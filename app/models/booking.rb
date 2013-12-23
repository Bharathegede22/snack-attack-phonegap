class Booking < ActiveRecord::Base

	belongs_to :car
	belongs_to :cargroup
	belongs_to :location
	belongs_to :user
	
	has_many	:charges, :inverse_of => :booking, dependent: :destroy
	has_many	:payments, :inverse_of => :booking, dependent: :destroy
	has_many	:refunds, :inverse_of => :booking, dependent: :destroy
	has_many	:confirmed_payments, -> { where "status = 1" }, class_name: "Payment"
	has_many	:confirmed_refunds, -> { where "status = 1" }, class_name: "Refund"
	has_many	:reviews, :inverse_of => :booking, dependent: :destroy
	has_many	:utilizations, -> {where "minutes > 0"}, dependent: :destroy
	
	attr_writer :through_search
	attr_writer :through_signup
    
	validates :starts, :ends, presence: true
	validates :cargroup_id, :location_id, presence: true, if: Proc.new {|b| !b.through_search?}
	validates :cargroup_id, :location_id, :user_id, presence: true, if: Proc.new {|b| b.through_signup?}
	validate :dates_order
	
	after_create :after_create_tasks
	after_save :after_save_tasks
	before_save :before_save_tasks
	
	def check_fare(start_date, end_date)
		temp = {:estimate => 0, :discount => 0, :days => 0, :normal_days => 0, :discounted_days => 0, :hours => 0, :normal_hours => 0, :discounted_hours => 0}
		cargroup = self.cargroup
		rate = [cargroup.hourly_fare, cargroup.daily_fare]
		h = (end_date.to_i - start_date.to_i)/3600
		h += 1 if (end_date.to_i - start_date.to_i) > h*3600
		d = h/24
		h = h - d*24
		temp[:days] = d
		temp[:hours] = h
		
		# Daily Fair
		if d > 0
			(0..(d-1)).each do |i|
				wday = (start_date + i.days).wday
				temp[:estimate] += rate[1]
				if wday > 0 && wday < 5
					temp[:discount] += rate[1]*0.35
					temp[:discounted_days] += 1
				else
					temp[:normal_days] += 1
				end
			end
		end
		# Hourly Fair
		wday = (start_date + d.days).wday
		if h <= 10
			tmp = rate[0]*h
		else
			tmp = rate[1]
		end
		temp[:estimate] += tmp
		if wday > 0 && wday < 5
			temp[:discount] += tmp*0.35
			temp[:discounted_hours] += h
		else
			temp[:normal_hours] += h
		end
		temp[:estimate] = temp[:estimate].round
		temp[:discount] = temp[:discount].round
		return temp
	end
	
	def check_payment
		total = self.outstanding
		if total > 0
			payment = Payment.create!(booking_id: self.id, through: 'payu', amount: total)
		else
			payment = nil
		end
		return payment
	end
	
	def dates_order
		if !self.starts.blank? && !self.ends.blank?
			if self.starts > self.ends
				errors.add(:ends, "can't be less than the starting time")
			elsif (self.starts + 1.hours) > self.ends
				errors.add(:ends, "can't be within one hour of starting time")
			end
		end
	end
	
	def encoded_id
		CommonHelper.encode('booking', self.id)
	end
	
	def outstanding
		total = 0
		self.charges.each do |c|
			if c.activity != 'early_return_refund'
				if c.refund > 0
					total -= c.amount
				else
					total += c.amount
				end
			end
		end
		self.confirmed_payments.each do |p|
			total -= p.amount
		end
		self.confirmed_refunds.each do |r|
			total -= r.amount if r.through != 'early_return_credits'
		end		
		return total.to_i
	end
	
	def set_fare
		tmp = check_fare(self.starts, self.ends)
		self.estimate = tmp[:estimate].round
		self.discount = tmp[:discount].round
		self.days = tmp[:days]
		self.normal_days =  tmp[:normal_days]
		self.discounted_days = tmp[:discounted_days]
		self.hours = tmp[:hours]
		self.normal_hours = tmp[:normal_hours]
		self.discounted_hours = tmp[:discounted_hours]
		self.total = self.estimate - self.discount
	end
	
	def setup
		self.actual_starts = self.starts
		self.actual_ends = self.ends
		self.last_starts = self.starts
		self.last_ends = self.ends
		cargroup = self.cargroup
		if cargroup
			self.daily_fare = cargroup.daily_fare
			self.hourly_fare = cargroup.hourly_fare
			self.hourly_km_limit = cargroup.hourly_km_limit
			self.daily_km_limit = cargroup.daily_km_limit
		end
	end
	
	def status?
		if self.status > 5
			return 'cancelled'
		else
			if self.starts <= Time.zone.now && self.ends >= Time.zone.now
				return 'live'
			elsif self.starts > Time.zone.now
				return 'future'
			elsif self.ends < Time.zone.now
				return 'completed'
			end
		end
	end
	
	def status_help
		txt = case self.status.to_i
		when 0 then 'Booking initiated but no payment received.'
		when 1 then 'Booking confirmed and payment received.'
		when 2 then 'Checkout'
		when 5 then 'Completed'
		when 6 then 'No Inventory'
		when 7 then 'No Car'
		when 9 then 'No Show'
		when 10 then 'Cancelled'
		else '-'
		end
		txt << "<br/>"
		txt << "Early<br/>" if self.early
		txt << "Late<br/>" if self.late
		txt << "Extended<br/>" if self.extended
		txt << "Rescheduled<br/>" if self.rescheduled
		return txt.html_safe
	end
	
	def status_text
		txt = case self.status.to_i
		when 0 then 'Initiated'
		when 1 then 'Paid'
		when 2 then 'Checkout'
		when 5 then 'Completed'
		when 6 then 'No Inventory'
		when 7 then 'No Car'
		when 9 then 'No Show'
		when 10 then 'Cancelled'
		else '-'
		end
		return txt
	end
	
	def through_search?
    @through_search
  end
  
  def through_signup?
    @through_signup
  end
  
  protected
	
	def after_create_tasks
		charge = Charge.new(:booking_id => self.id, :activity => 'booking_fee')
		charge.hours = self.days*24 + self.hours
		charge.billed_total_hours = self.days*10
		charge.billed_total_hours += (self.hours > 10 ? 10 : self.hours)
		charge.billed_discounted_hours = self.discounted_days*10
		charge.billed_discounted_hours += (self.discounted_hours > 10 ? 10 : self.discounted_hours)
		charge.billed_standard_hours = self.normal_days*10
		charge.billed_standard_hours += (self.normal_hours > 10 ? 10 : self.normal_hours)
		charge.estimate = self.estimate.round
		charge.discount = self.discount.round
		charge.amount = (charge.estimate - charge.discount)
		charge.save
	end
	
	def after_save_tasks
		Utilization.manage(self)
	end
	
	def before_save_tasks
		if self.id.blank?
			setup
			set_fare
			self.notes = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs." + self.total.to_i.to_s + " - Booking Charges."
			self.notes += self.starts.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
		else
			if false
				if self.status < 5
					if self.starts != self.last_starts || self.ends != self.last_ends
						check_extended
						check_short
					end
					check_early
					check_late
				end 
				if !self.returned_at.blank?
					self.ends = self.returned_at
					self.status = 5
				end
				if !self.comment.blank?
					self.notes += "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : Comment Added - </b>" + self.comment + "<br/>"
					self.comment = ''
				end
				if self.status > 8
					handle_cancellation
				else
					check_mileage
				end
			end
		end
		self.last_starts = self.starts
		self.last_ends = self.ends
		self.unblocks = self.ends + self.cargroup.wait_period.minutes
	end
	
end
