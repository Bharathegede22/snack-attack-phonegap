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
	has_many	:utilizations, -> {where "minutes > 0"}, dependent: :destroy
	
	has_one	:review, :inverse_of => :booking, dependent: :destroy
	has_many :credit, :as => :creditable , dependent: :destroy

	attr_writer :through_search
	attr_writer :through_signup
    
	validates :starts, :ends, presence: true
	validates :cargroup_id, :location_id, presence: true, if: Proc.new {|b| !b.through_search?}
	validates :cargroup_id, :location_id, :user_id, presence: true, if: Proc.new {|b| b.through_signup?}
	validate :dates_order
	
	after_create :after_create_tasks
	after_save :after_save_tasks
	before_save :before_save_tasks
	
	def block_extension
		if self.car_id.blank?
			return Inventory.block_extension(self.cargroup_id, self.location_id, self.last_ends, self.ends)
		else
			c = self.car
			check = c.check_extension(self.last_ends, self.ends)
			c.manage_inventory(self.last_ends, self.ends, true) if check == 1
			return check
		end
	end
	
	def cancellation_charge
		total = Charge.find_by_booking_id_and_activity(self.id, 'cancellation_charge')
		if total
			return total.amount
		else
			return 0
		end
	end
	
	def check_cancellation
		total = 0
		self.charges.each do |c|
			if !c.activity.include?('charge')
				if c.refund > 0
					total -= c.amount
				else
					total += c.amount
				end
			end
		end
		if Time.now > (self.starts - 24.hours)
			if (0.25*total).round > 2000
				total -= 2000
			else
				total -= (total*0.25).round
			end
		end
		return total
	end
	
	def check_extension
		if self.car_id.blank?
			return Inventory.check_extension(self.last_ends, self.ends, self.cargroup_id, self.location_id)
		else
			return self.car.check_extension(self.last_ends, self.ends)
		end
	end
	
	def check_late
		data = {:hours => 0, :billed_hours => 0, :standard_hours => 0, :discounted_hours => 0, :estimate => 0, :discount => 0}
		if !self.returned_at.blank? && self.returned_at > (self.ends + 30.minutes)
			cargroup = self.cargroup
			rate = cargroup.hourly_fare
			data[:hours] = (self.returned_at.to_i - self.ends.to_i)/3600
			data[:hours] += 1 if (self.returned_at.to_i - self.ends.to_i) > data[:hours]*3600
			data[:billed_hours] += data[:hours]
			min = 1
			wday = self.ends.wday
			while min <= data[:hours]*60
				if min == ((min/60)*60)
					data[:estimate] += rate
					if [0,5,6].include?(wday)
						data[:standard_hours] += 1
					else
						data[:discounted_hours] += 1
						data[:discount] += rate*(CommonHelper::WEEKDAY_DISCOUNT/100.0)
					end
					wday = (self.ends + min.minutes).wday
				end
				min += 1
			end
		end
		return data
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
	
	def status_complete?
		if ends < Time.zone.now && status < 8 && status > 0
			return true
		else 
			return false
		end
	end
	
	def check_reschedule
		str, fare = ['', nil]
		if !self.returned_at.blank?
			if self.returned_at < self.ends
				str, fare = ['Early Return', get_adjusted_fare('early')]
			elsif self.returned_at > self.ends
				str, fare = ['Late', check_late]
			end
		elsif (self.starts != self.last_starts || self.ends != self.last_ends)
			if self.ends > self.last_ends
				check = self.check_extension
				if check == 1
					str, fare = ['Extending', get_adjusted_fare('extend')]
				else
					BookingMailer.change_failed(self).deliver
					str, fare = ['NA', nil]
				end
			elsif self.ends < self.last_ends
				str, fare = ['Shortening', get_adjusted_fare('short')]
			end
		end
		return [str, fare]
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
	
	def do_cancellation
		total = 0
		if self.status < 9
			self.manage_inventory(self.starts, self.ends, false)
			self.charges.each do |c|
				if !c.activity.include?('charge')
					if c.refund > 0
						total -= c.amount
					else
						total += c.amount
					end
				end
			end
			if Time.now > (self.starts - 24.hours)
				fee = (0.25*total).round
				fee = 2000 if fee > 2000
			else
				fee = 0
			end
			charge = Charge.new(:booking_id => self.id, :refund => 1, :activity => 'cancellation_refund', :estimate => total, :discount => 0, :amount => total)
			if charge.save
				note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs."
				note += total.to_s + " - Cancellation Refund.<br/>"
				self.notes += note
			end
			if fee > 0
				total -= fee
				charge = Charge.new(:booking_id => self.id, :activity => 'cancellation_charge', :estimate => fee, :discount => 0, :amount => fee)
				if charge.save
					note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs."
					note += fee.to_s + " - Cancellation Charge.<br/>"
					self.notes += note
				end
			end
			self.status = 10
			self.save(validate: false)
			BookingMailer.cancel(self.id, charge).deliver
		end
		return total
	end
	
	def do_reschedule
		str, fare = ['', nil]
		if !self.returned_at.blank?
			if self.returned_at < self.ends
				action_text = 'early_return_refund'
				str, fare = ['Early Return', get_fare('early')]
				self.early = true
			elsif self.returned_at > (self.ends + 30.minutes)
				action_text = 'late_fee'
				str, fare = ['Late Return', check_late]
				self.late = true
			end
		elsif (self.starts != self.last_starts || self.ends != self.last_ends)
			if self.ends > self.last_ends
				action_text = 'extension_fee'
				check = self.block_extension
				if check == 1
					str, fare = ['Extending', get_fare('extend')]
					self.extended = true
				else
					BookingMailer.change_failed(self).deliver
					str, fare = ['NA', nil]
				end
			elsif self.ends < self.last_ends
				action_text = 'shortened_trip_refund'
				str, fare = ['Shortening', get_fare('short')]
				self.manage_inventory(self.ends, self.last_ends, false)
				self.rescheduled = true
			end
		end
		if fare
			if fare[:billed_hours] > 0
				charge = Charge.new(:booking_id => self.id, :activity => action_text, :estimate => 0, :discount => 0, :amount => 0)
				charge.hours = fare[:hours].round
				charge.billed_total_hours += fare[:billed_hours].round
				charge.billed_discounted_hours += fare[:discounted_hours].round
				charge.billed_standard_hours += fare[:standard_hours].round
				charge.estimate += fare[:estimate]
				charge.discount += fare[:discount]
				charge.amount += (fare[:estimate] - fare[:discount])
				charge.refund = 1 if action_text.include?('refund')
				if charge.save
					note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs."
					note << case str
					when 'Early Return' then charge.amount.to_s + ' - Early Return Credits.' + self.ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.returned_at.strftime("%d/%m/%y %I:%M %p") + "<br/>"
					when 'Late Return' then charge.amount.to_s + " - Late Charges." + self.ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.returned_at.strftime("%d/%m/%y %I:%M %p") + "<br/>"
					when 'Extending' then charge.amount.to_s + " - Extension Charges." + self.last_ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
					when 'Shortening' then charge.amount.to_s + " - Reschedule Refund." + self.last_ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
					end
					self.notes += note
				end
				# Trip modification charges
				if action_text == 'early_return_refund' || (action_text == 'shortened_trip_refund' && (Time.now > (self.ends - 24.hours)))
					fare_new = case action_text 
					when 'early_return_refund' then get_adjusted_fare('early')
					when 'shortened_trip_refund' then get_adjusted_fare('short')
					end
					charge = Charge.new(:booking_id => self.id, :activity => action_text.gsub('refund', 'charge'), :estimate => 0, :discount => 0, :amount => 0)
					charge.hours = fare[:hours].round
					charge.billed_total_hours += fare[:billed_hours].round
					charge.billed_discounted_hours += fare[:discounted_hours].round
					charge.billed_standard_hours += fare[:standard_hours].round
					charge.estimate += (fare[:estimate] - fare_new[:estimate])
					charge.discount += (fare[:discount] - fare_new[:discount])
					charge.amount += charge.estimate - charge.discount
					if charge.save
						note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs."
						note << case str
						when 'Early Return' then charge.amount.to_s + ' - Early Return Charge.' + self.ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.returned_at.strftime("%d/%m/%y %I:%M %p") + "<br/>"
						when 'Shortening' then charge.amount.to_s + " - Reschedule Charge." + self.last_ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
						end
						note << self.starts.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
						self.notes += note
					end
				end
			else
				note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b>"
				note << case str
				when 'Early Return' then 'No Early Return Credits.' + self.ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.returned_at.strftime("%d/%m/%y %I:%M %p") + "<br/>"
				when 'Extending' then "No Extension Charges." + self.last_ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
				when 'Shortening' then "No Reschedule Refund." + self.last_ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
				end
				self.notes += note
			end
			self.save(validate: false)
			if charge
				BookingMailer.change(self.id, charge).deliver
			else
				BookingMailer.change(self.id, nil).deliver
			end
		end
		return [str, fare]
	end
	
	def encoded_id
		CommonHelper.encode('booking', self.id)
	end
	
	def get_adjusted_fare(action)
		data = get_fare(action)
		if data[:billed_hours] > 0
			if action == 'early'
				data[:estimate] = (data[:estimate]/4).round
				data[:discount] = (data[:discount]/4).round
			elsif action == 'short' && (Time.now > (self.ends - 24.hours))
				data[:estimate] = (data[:estimate]/2).round
				data[:discount] = (data[:discount]/2).round
			end
		end
		data[:estimate] = data[:estimate].round
		data[:discount] = data[:discount].round
		return data
	end
	
	def get_fare(action)
		case action
		when 'early'
			start_date = self.starts
			end_date_old = self.returned_at
			end_date_new = self.ends
		when 'extend'
			start_date = self.starts
			end_date_old = self.last_ends
			end_date_new = self.ends
		when 'short'
			start_date = self.starts
			end_date_old = self.ends
			end_date_new = self.last_ends
		end
		data = {:hours => 0, :billed_hours => 0, :standard_hours => 0, :discounted_hours => 0, :estimate => 0, :discount => 0}
		cargroup = self.cargroup
		rate = {:hourly => (cargroup.hourly_fare/60.0), :daily => cargroup.daily_fare, :weekly => cargroup.weekly_fare, :monthly => cargroup.monthly_fare}
		
		# Old Values
		min_old = (end_date_old.to_i - start_date.to_i)/60
		hour_old = min_old/60
		hour_old += 1 if (end_date_old.to_i - start_date.to_i) > hour_old*3600
		
		# New Values
		min_new = (end_date_new.to_i - start_date.to_i)/60
		hour_new = min_new/60
		hour_new += 1 if (end_date_new.to_i - start_date.to_i) > hour_new*3600
		
		data[:hours] = hour_new - hour_old
		data[:days] = data[:hours]/24
		data[:hours] = data[:hours] - (data[:hours]/24)*24
		
		min = 0
		billed = 0
		billed_total = 0
		daily = {:actual => 0, :billed => 0}
		daily_last = {:actual => 0, :billed => 0}
		wday = start_date.wday
		wday_c = start_date.wday
		array = []
		rev = 0
		disc = 0
		
		if (hour_new/24) >= 7
			hour_process = 7*24
		else
			hour_process = hour_new
		end
		
		# Hourly / Daily Tariff
		if (hour_old/24) < 7
			while min <= (hour_process*60)
				if (min-((min/1440)*1440)) == 0
					billed = 0
					wday_c = (start_date + min.minutes).wday
				end
				if ((((start_date + min.minutes).hour == 0) && ((start_date + min.minutes).min == 0)) || (min == hour_process*60))
					if daily_last[:billed] > 0
						array_last = array.last
						if array_last && ((array_last + daily_last[:actual]) >= 600)
							rev = (rate[:daily] - ((600 - daily_last[:billed])*rate[:hourly]))
						else
							rev = daily_last[:billed]*rate[:hourly]
						end
						if [0,1,6].include?(wday)
							data[:standard_hours] += daily_last[:billed]/60
							disc = 0
						else
							data[:discounted_hours] += daily_last[:billed]/60
							disc = rev*(CommonHelper::WEEKDAY_DISCOUNT/100.0)
						end
						data[:estimate] += rev
						data[:discount] += disc
					end
					if daily[:billed] > 0
						if (daily[:actual] >= 600)
							rev = (rate[:daily] - ((600 - daily[:billed])*rate[:hourly]))
						else
							rev = daily[:billed]*rate[:hourly]
						end
						if [0,5,6].include?(wday)
							data[:standard_hours] += daily[:billed]/60
							disc = 0
						else
							data[:discounted_hours] += daily[:billed]/60
							disc = rev*(CommonHelper::WEEKDAY_DISCOUNT/100.0)
						end
						data[:estimate] += rev
						data[:discount] += disc
					end
					array << daily[:actual]
					daily = {:actual => 0, :billed => 0}
					daily_last = {:actual => 0, :billed => 0}
					wday = (start_date + min.minutes).wday
					date = (start_date + min.minutes).to_date
				end
				if billed < 600
					if wday == wday_c
						daily[:actual] += 1
						daily[:billed] += 1 if min >= (hour_old*60)
					else
						daily_last[:actual] += 1
						daily_last[:billed] += 1 if min >= (hour_old*60)
					end
					billed_total += 1 if min >= (hour_old*60)
				end
				billed += 1
				min += 1
			end
			data[:billed_hours] = billed_total/60
		end
		
		# Weekly Tariff
		if (hour_new/24) >= 7 && (hour_old/24) < 28
			if (hour_new/24) >= 28
				hour_process = 21*24
			else
				hour_process = hour_new - (24*7)
			end
			hour_process -= (hour_old - (24*7)) if (hour_old/24) >= 7
			data[:estimate] += (hour_process * (rate[:weekly]/(7*24.0)))
			data[:billed_hours] += hour_process
		end
		
		# Monthly Tariff
		if (hour_new/24) >= 28
			hour_process = hour_new - (24*28)
			hour_process -= (hour_old - (24*28)) if (hour_old/24) >= 28
			data[:estimate] += (hour_process * (rate[:monthly]/(28*24.0)))
			data[:billed_hours] += hour_process
		end
		#debugger
		data[:estimate] = data[:estimate].round
		data[:discount] = data[:discount].round
		return data
	end
	
	def link
		return "http://" + HOSTNAME + "/bookings/" + self.encoded_id
	end
	
	def manage_inventory(start_time, end_time, block)
		if self.car_id.blank?
			if block
				# Block Inventory
				Inventory.block_plain(self.cargroup_id, self.location_id, start_time, end_time)
			else
				# Release Inventory
				Inventory.release(self.cargroup_id, self.location_id, start_time, end_time)
			end
		else
			self.car.manage_inventory(start_time, end_time, block)
		end
	end
	
	def outstanding
		total = self.total_charges
		total -= self.total_payments
		total += self.total_refunds
		return total.to_i
	end
	
	def revenue
		tmp = 0
		self.charges.each do |a|
			if !a.activity.include?('early_return') && !['vehicle_damage_fee', 'fuel_refund', 'andhra_permit_refund'].include?(a.activity)
				if a.refund > 0
					tmp -= a.amount.to_i
				else
					tmp += a.amount.to_i
				end
			end
		end
		self.confirmed_payments.each do |a|
			tmp -= a.amount.to_i if a.through == 'credits'
		end
		return tmp
	end
	
	def paid?
		return (self.status > 0 || !self.jsi.blank?)
	end
	
	def set_fare
		tmp = self.cargroup.check_fare(self.starts, self.ends)
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
		self.user_name = self.user_name.strip if !self.user_name.blank?
		self.user_email = self.user_email.strip.downcase if !self.user_email.blank?
		cargroup = self.cargroup
		if cargroup
			self.daily_fare = cargroup.daily_fare
			self.hourly_fare = cargroup.hourly_fare
			self.hourly_km_limit = cargroup.hourly_km_limit
			self.daily_km_limit = cargroup.daily_km_limit
		end
	end
	
	def status?
		if self.status > 8
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
		if self.jsi.blank?
			txt = case self.status.to_i
			when 0 then 'Booking NOT CONFIRMED as payment not received.'
			when 1 then 'Booking confirmed and payment received.'
			when 2 then 'Checkout'
			when 5 then 'Completed'
			when 6 then 'No Inventory'
			when 7 then 'No Car'
			when 9 then 'No Show'
			when 10 then 'Cancelled'
			else '-'
			end
		else
			txt = case self.status.to_i
			when 0 then 'Booking confirmed, but payment not received.'
			when 1 then 'Booking confirmed and payment received.'
			when 2 then 'Checkout'
			when 5 then 'Completed'
			when 6 then 'No Inventory'
			when 7 then 'No Car'
			when 9 then 'No Show'
			when 10 then 'Cancelled'
			else '-'
			end
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
	
	def total_charges
		total = 0
		self.charges.each do |c|
			if !c.activity.include?('early_return')
				if c.refund > 0
					total -= c.amount
				else
					total += c.amount
				end
			end
		end
		return total.to_i
	end
	
	def total_payments
		total = 0
		self.confirmed_payments.each do |p|
			total += p.amount
		end
		return total.to_i
	end
	
	def total_refunds
		total = 0
		self.confirmed_refunds.each do |r|
			total += r.amount if !r.through.include?('early_return')
		end		
		return total.to_i
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
		self.confirmation_key = self.encoded_id.upcase
		self.save(validate: false)
	end
	
	def after_save_tasks
		Utilization.manage(self.id) if !self.jsi.blank? || self.status > 0
		Exotel.send_message(self.user_mobile, "Zoom booking (#{self.confirmation_key}) for #{self.cargroup.display_name} at #{self.starts.strftime('%I:%M %p, %d %b')} is confirmed. Zoom Support : 08067684475.", self.id) if self.status_changed? && (self.status == 1 || self.status == 6)
	end
	
	def before_save_tasks
		if self.id.blank?
			setup
			set_fare
			self.notes = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs." + self.total.to_i.to_s + " - Booking Charges."
			self.notes += self.starts.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
		else
			if !self.returned_at.blank?
				self.ends = self.returned_at
				self.status = 5
			end
			if !self.comment.blank?
				self.notes += "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : Comment Added - </b>" + self.comment + "<br/>"
				self.comment = ''
			end
			self.total = self.revenue
			self.balance = self.outstanding
		end
		self.last_starts = self.starts
		self.last_ends = self.ends
	end
	
end
