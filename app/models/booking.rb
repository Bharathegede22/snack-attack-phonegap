class Booking < ActiveRecord::Base
	
	belongs_to :car
	belongs_to :cargroup
	belongs_to :city
	belongs_to :corporate
	belongs_to :location
	belongs_to :offer
	belongs_to :pricing
	belongs_to :user
	
	has_many	:charges, :inverse_of => :booking, dependent: :destroy
	has_many	:payments, :inverse_of => :booking, dependent: :destroy
	has_many	:refunds, :inverse_of => :booking, dependent: :destroy
	has_many	:confirmed_payments, -> { where "status = 1" }, class_name: "Payment"
	has_many	:confirmed_refunds, -> { where "status = 1" }, class_name: "Refund"
	has_many 	:credit, :as => :creditable , dependent: :destroy
	has_many	:utilizations, -> {where "minutes > 0"}, dependent: :destroy
	
	has_one :coupon_code
	has_one	:review, :inverse_of => :booking, dependent: :destroy
	has_one :debug, :as => :debugable, dependent: :destroy
	
	has_paper_trail
	
	attr_accessor :ends_last
	attr_accessor :pricing_mode_last
	attr_accessor :starts_last
	attr_writer :through_search
	attr_writer :through_signup
    
	validates :starts, :ends, :city_id, :pricing_id, presence: true
	validates :cargroup_id, :location_id, presence: true, if: Proc.new {|b| !b.through_search?}
	validates :cargroup_id, :location_id, :user_id, presence: true, if: Proc.new {|b| b.through_signup?}
	validate :dates_order
	
	after_create :after_create_tasks
	after_save :after_save_tasks
	before_create :before_create_tasks
	before_save :before_save_tasks
	before_validation :before_validation_tasks
	
	def block_extension
		if self.car_id.blank?
			return Inventory.block_extension(self.city, self.cargroup_id, self.location_id, self.ends_lasts, self.ends)
		else
			c = self.car
			check = c.check_extension(self.city, self.ends_last, self.ends)
			c.manage_inventory(self.city, self.ends_last, self.ends, true) if check == 1
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
	
	def check_extension
		if self.car_id.blank?
			return Inventory.check_extension(self.last_ends, self.ends, self.city, self.cargroup_id, self.location_id)
		else
			return self.car.check_extension(self.city, self.last_ends, self.ends)
		end
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
			if self.new_record?
		    errors.add(:starts, "Booking cannot be made more than #{CommonHelper::BOOKING_WINDOW} days in advance") if starts > Time.today + CommonHelper::BOOKING_WINDOW.days
		    errors.add(:starts, "cannot be in the past") if starts < Time.now
		    
		    errors.add(:ends, "Booking cannot be made more than #{CommonHelper::BOOKING_WINDOW} days in advance") if ends > Time.today + CommonHelper::BOOKING_WINDOW.days
		    errors.add(:ends, "cannot be in the past") if ends < Time.now
		  end
			if self.starts > self.ends
				errors.add(:ends, "can't be less than the starting time")
			elsif (self.starts + 1.hours) > self.ends
				errors.add(:ends, "can't be within one hour of starting time")
			end
		end
	end
	
	def do_cancellation
		if self.status < 9
			self.manage_inventory(self.city, self.starts, self.ends, false)
			fare = self.get_fare
			charge = Charge.new(booking_id: self.id, refund: 1, activity: 'cancellation_refund', estimate: data[:refund], discount: 0, amount: data[:refund])
			if charge.save
				note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs."
				note += data[:refund].to_s + " - Cancellation Refund.<br/>"
				self.notes += note
			end
			if data[:penalty] > 0
				charge = Charge.new(booking_id: self.id, activity: 'cancellation_charge', estimate: data[:penalty], discount: 0, amount: data[:penalty])
				if charge.save
					note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs."
					note += data[:penalty].to_s + " - Cancellation Charge.<br/>"
					self.notes += note
				end
			end
			self.status = 10
			self.save(validate: false)
			BookingMailer.cancel(self.id, charge.id).deliver
			sendsms('cancel', (data[:refund] - data[:penalty]))
		end
		return (data[:refund] - data[:penalty])
	end
	
	def do_reschedule
		str = ''
		fare = self.get_fare
		if fare[:log]
			if !self.returned_at.blank?
				if fare[:total_hours] < 0
					action_text = 'early_return_refund'
					str = 'Early Return'
					self.early = true
				else
					action_text = 'late_fee'
					str = 'Late Return'
					self.late = true
				end
			elsif self.starts != self.starts_last
				str = 'Rescheduling'
				self.rescheduled = true
				if fare[:total_hours] > 0
					action_text = 'reschedule_fee'
					check = self.block_extension
					if check != 1
						BookingMailer.change_failed(self.id).deliver
						str = 'NA'
					end
				elsif fare[:total_hours] < 0
					action_text = 'reschedule_refund'
					self.manage_inventory(self.city, self.ends, self.ends_last, false)
				end
			elsif self.ends != self.ends_last
				if self.ends > self.ends_last
					action_text = 'extension_fee'
					check = self.block_extension
					if check == 1
						str = 'Extending'
						self.extended = true
					else
						BookingMailer.change_failed(self.id).deliver
						str = 'NA'
					end
				else
					action_text = 'shortened_trip_refund'
					str = 'Shortening'
					self.manage_inventory(self.city, self.ends, self.last_ends, false)
					self.shortened = true
				end
			end
			if fare[:billed_hours] > 0
				charge = Charge.new(booking_id: self.id, activity: action_text, estimate: 0, discount: 0, amount: 0)
				charge.hours = fare[:hours].round
				charge.billed_total_hours += fare[:billed_hours].round
				charge.billed_discounted_hours += fare[:discounted_hours].round
				charge.billed_standard_hours += fare[:standard_hours].round
				charge.estimate += fare[:estimate]
				charge.discount += fare[:discount]
				if fare[:refund] > 0
					charge.amount += fare[:refund]
					charge.refund = 1
				else
					charge.amount += fare[:total]
				end
				if charge.save
					note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs."
					note << case str
					when 'Early Return' then charge.amount.to_s + ' - Early Return Credits.' + self.ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.returned_at.strftime("%d/%m/%y %I:%M %p") + "<br/>"
					when 'Late Return' then charge.amount.to_s + " - Late Charge." + self.ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.returned_at.strftime("%d/%m/%y %I:%M %p") + "<br/>"
					when 'Rescheduling' 
						if charge.refund
							charge.amount.to_s + " - Reschedule Charge." + self.last_ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
						else
							charge.amount.to_s + " - Reschedule Refund." + self.last_ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
						end
					when 'Extending' then charge.amount.to_s + " - Extension Charges." + self.last_ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
					when 'Shortening' then charge.amount.to_s + " - Shorten Refund." + self.last_ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
					end
					self.notes += note
				end
				# Trip modification charges
				if fare[:penalty] > 0
					charge = Charge.new(booking_id: self.id, activity: action_text.gsub('refund', 'charge'), estimate: 0, discount: 0, amount: 0)
					charge.hours = fare[:hours].round
					charge.billed_total_hours += fare[:billed_hours].round
					charge.billed_discounted_hours += fare[:discounted_hours].round
					charge.billed_standard_hours += fare[:standard_hours].round
					charge.estimate += fare[:penalty]
					charge.discount += 0
					charge.amount += fare[:penalty]
					if charge.save
						note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs."
						note << case str
						when 'Early Return' then charge.amount.to_s + ' - Early Return Charge.' + self.ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.returned_at.strftime("%d/%m/%y %I:%M %p") + "<br/>"
						else charge.amount.to_s + " - Reschedule Charge." + self.last_ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
						end
						note << self.starts.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
						self.notes += note
					end
				end
			else
				note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b>"
				note << case str
				when 'Early Return' then 'No Early Return Credits.' + self.ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.returned_at.strftime("%d/%m/%y %I:%M %p") + "<br/>"
				when 'Rescheduling' then 'No Reschedule Charges.' + self.ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.returned_at.strftime("%d/%m/%y %I:%M %p") + "<br/>"
				when 'Extending' then "No Extension Charges." + self.last_ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
				when 'Shortening' then "No Reschedule Refund." + self.last_ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
				end
				self.notes += note
			end
			self.save(validate: false)
			if charge
				BookingMailer.change(self.id, charge.id).deliver
				if charge.refund == 1
					sendsms('change', -1 * charge.amount.to_i)
				else
					sendsms('change', charge.amount.to_i)
				end
			else
				BookingMailer.change(self.id, nil).deliver
				sendsms('change', 0)
			end
		end
		return [str, fare]
	end
	
	def downgraded?
		if self.pricing_mode_changed?
			case self.pricing_mode_was
			when 'm'
				return true if self.pricing_mode == 'w' || self.pricing_mode == 'h'
			when 'w'
				return true if self.pricing_mode == 'h'
			end
		end
		return false
	end
	
	def encoded_id
		CommonHelper.encode('booking', self.id)
	end
	
	def through_search?
    @through_search
  end
  
	def get_fare
		return "Pricing#{self.pricing.version}".constantize.check(self)
	end
	
	def link
		return "http://" + HOSTNAME + "/bookings/" + self.encoded_id
	end
	
	def manage_inventory(city, start_time, end_time, block)
		if self.car_id.blank?
			if block
				# Block Inventory
				Inventory.block_plain(city, self.cargroup_id, self.location_id, start_time, end_time)
			else
				# Release Inventory
				Inventory.release(city, self.cargroup_id, self.location_id, start_time, end_time)
			end
		else
			self.car.manage_inventory(city, start_time, end_time, block)
		end
	end
	
	def outstanding
		total = self.total_charges
		total -= self.total_payments
		total += self.total_refunds
		return total.to_i
	end
	
	def refund_amount
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
		return total
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
	
	def self.recalculate(id)
		Booking.connection.clear_query_cache
		#book = Booking.unscoped.find(id)
		book = Booking.find(id)
		book.update_columns(total: book.revenue, balance: book.outstanding)
		#Utilization.manage(id)
	end

	def set_fare
		tmp = "Pricing#{self.pricing.version}".constantize.check(self)
		self.total = tmp[:estimate]
		self.estimate = tmp[:estimate]
		self.discount = tmp[:discount]
		self.days = tmp[:days]
		self.normal_days =  tmp[:normal_days]
		self.discounted_days = tmp[:discounted_days]
		self.hours = tmp[:hours]
		self.normal_hours = tmp[:normal_hours]
		self.discounted_hours = tmp[:discounted_hours]
	end
	
	def sendsms(action, amount)
		message =  case action 
		when 'change' then "Zoom booking (#{self.confirmation_key}) is changed. #{self.cargroup.display_name} from #{self.starts.strftime('%I:%M %p, %d %b')} till #{self.ends.strftime('%I:%M %p, %d %b')} at #{self.location.shortname}. "
		when 'cancel' then "Zoom booking (#{self.confirmation_key}) is cancelled. Rs.#{amount} will be refunded back to your account in 4 days. "
		end
		if action != 'cancel'
			if amount == 0
				message << "No change in booking amount. "
			elsif amount < 0
				message << "Rs.#{-1*amount.to_i} will be refunded once your booking concludes. "
			else
				message << "Rs.#{amount.to_i} is outstanding. "
			end
		end
		support_contact = City.find(self.city_id).contact_phone
		message << "#{support_contact} : Zoom Support."
		SmsSender.perform_async(self.user_mobile, message, self.id)
	end
	
	def setup
		self.actual_starts = self.starts
		self.actual_ends = self.ends
		self.ends_last = self.ends_was
		self.pricing_mode_last = self.pricing_mode_was
		self.starts_last = self.starts_was
		self.user_name = self.user_name.strip if !self.user_name.blank?
		self.user_email = self.user_email.strip.downcase if !self.user_email.blank?
	end
	
	def status_complete?
		if ends < Time.zone.now && status < 8 && status > 0
			return true
		else 
			return false
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
	end
	
	def before_create_tasks
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

	def before_validation_tasks
		self.ends_last = self.ends_was if self.ends_last.blank?
		self.pricing_mode_last = self.pricing_mode_was if self.pricing_mode_last.blank?
		self.starts_last = self.starts_was if self.starts_last.blank?
		if self.pricing_id.blank? && !self.cargroup_id.blank? && !self.city_id.blank?
			self.pricing_id = self.cargroup.active_pricing(self.city_id).id
		end
	end
	
end
