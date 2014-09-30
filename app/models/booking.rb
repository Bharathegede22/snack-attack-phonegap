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
	has_many	:confirmed_payments, -> { where "status = 1 and through != 'wallet_widget'" }, class_name: "Payment"
	has_many	:confirmed_refunds, -> { where "status = 1 and through != 'wallet_widget'" }, class_name: "Refund"
	has_many 	:credit, :as => :creditable , dependent: :destroy
	has_many	:utilizations, -> {where "minutes > 0"}, dependent: :destroy
	
	has_one :coupon_code
	has_one	:review, :inverse_of => :booking, dependent: :destroy
	has_one :debug, :as => :debugable, dependent: :destroy
	has_one :wallet_payment
	
	has_paper_trail
	
	attr_accessor :ends_last
	attr_accessor :pricing_mode_last
	attr_accessor :starts_last
	attr_writer :through_search
	attr_writer :through_signup
    
	validates :starts, :ends, :city_id, presence: true
	validates :cargroup_id, :location_id, :user_id, presence: true, if: Proc.new {|b| b.through_signup?}
	validate :dates_order
	
	after_create :after_create_tasks
	after_save :after_save_tasks
	before_create :before_create_tasks
	before_save :before_save_tasks
	before_validation :before_validation_tasks
	
	# Return a scope for all interval overlapping the given interval, including the given interval itself
	scope :overlapping, lambda { |interval| {
	:conditions => ["(DATEDIFF(starts, ?) * DATEDIFF(?, ends)) >= 0 AND user_id = ? AND status > 0 AND status < 5", interval.ends, interval.starts, interval.user_id]
	}}
	
	scope :overlapping_deposit, lambda { |interval| {
	:conditions => ["(DATEDIFF(starts, ?) * DATEDIFF(?, ends)) >= 0 AND user_id = ? AND status > 0 AND status < 5", interval.ends + CommonHelper::WALLET_FREEZE_END.hours, interval.starts - CommonHelper::WALLET_FREEZE_START.hours, interval.user_id]
	}}

	def add_security_deposit_charge(pay_wallet= false)
		return if !self.corporate_id.blank? || !security_charge.nil?
		charge 			= Charge.new(:booking_id => self.id, :activity => 'security_deposit')
		charge.amount 	= self.pricing.mode::SECURITY
		charge.save
		make_payment_from_wallet if pay_wallet
	end

	def add_security_deposit_to_wallet(amount= security_amount)
		return if (amount.to_i <= 0)
		refund = Refund.create!(status: 1, booking_id: self.id, through: 'wallet', amount: amount)
		Wallet.create!(amount: amount, user_id: self.user_id, status: 1, credit: true, transferable: refund)
		self.update_column(:hold, false) if amount.to_i >= 5000
	end

	def cancellation_charge
		total = Charge.find_by_booking_id_and_activity(self.id, 'cancellation_charge')
		if total
			return total.amount
		else
			return 0
		end
	end
	
	def check_inventory
		check = 1
		if self.car_id.blank?
			cargroup = self.cargroup
			Inventory.connection.clear_query_cache
			ActiveRecord::Base.connection.execute("LOCK TABLES inventories WRITE")
			if self.starts != self.starts_last || self.ends != self.ends_last
				if self.starts > self.ends_last + cargroup.wait_period.minutes || self.ends < self.starts_last - cargroup.wait_period.minutes
					# Non Overlapping Reschedule
					check = Inventory.check(self.city_id, self.cargroup_id, self.location_id, (self.starts - cargroup.wait_period.minutes), (self.ends + cargroup.wait_period.minutes))
				else
					# Overlapping Reschedule
					if self.starts < self.starts_last
						check = Inventory.check(self.city_id, self.cargroup_id, self.location_id, (self.starts - cargroup.wait_period.minutes), self.starts_last)
					end
					if check == 1 && self.ends > self.ends_last
						check = Inventory.check(self.city_id, self.cargroup_id, self.location_id, self.ends_last, (self.ends + cargroup.wait_period.minutes))
					end
				end
			else
				check = Inventory.check(self.city_id, self.cargroup_id, self.location_id, (self.starts - cargroup.wait_period.minutes), (self.ends + cargroup.wait_period.minutes))
			end
			ActiveRecord::Base.connection.execute("UNLOCK TABLES")
		else
			check = self.car.check_inventory(self.city_id, self.starts_last, self.ends_last, self.starts, self.ends)
		end
		return check
	end
	
	def check_payment
		total = defer_deposit ? self.outstanding_without_deposit : self.outstanding_with_security
		total = self.outstanding if self.status==5
		if total > 0
			payment = Payment.create!(booking_id: self.id, through: 'payu', amount: total)
		else
			payment = nil
		end
		return payment
	end
	
	def check_reschedule
		return ['', {}] if self.starts == self.starts_last && self.ends == self.ends_last
		check = self.check_inventory
		if check != 1
			BookingMailer.change_failed(self.id).deliver
			return ['NA', nil]
		end
		str, fare = ['', nil]
		if (self.starts != self.starts_last || self.ends != self.ends_last)
			if self.starts == self.starts_last
				if self.ends > self.ends_last
					str = 'Extending'
				elsif self.ends < self.ends_last
					str = 'Shortening'
				end
			else
				str = 'Rescheduling'
			end
		else
			str = 'No Change'
		end
		fare = self.get_fare
		return [str, fare]
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
	
	def defer_allowed?
		self.starts > (Time.now + CommonHelper::JIT_DEPOSIT_ALLOW.hours)
  end

  def defer_payment_allowed?
    self.starts > (Time.now + CommonHelper::JIT_DEPOSIT_ALLOW.hours + 30.minutes)
  end
	
	def deposit_help
		return "ZoomCar allows you to delay paying the Security Deposit. We really don’t want your money stuck in a deposit if your booking starts days from now."
	end
	
	def deposit_warning(remaining='')
		return "Please pay the #{remaining}deposit by <b>#{(self.starts - CommonHelper::JIT_DEPOSIT_CANCEL.hours).strftime('%d/%m/%y %I:%M %p')}</b> or your booking will get <u>cancelled</u>."
	end
	
	def do_cancellation
		return nil if self.status > 8
		self.release_payment = true
		self.status = 10
		self.manage_inventory
		data = self.get_fare
		charge = Charge.where(["booking_id = ? AND activity = 'cancellation_refund'", self.id]).first
		charge = Charge.new(booking_id: self.id, activity: 'cancellation_refund') if !charge
		charge.refund = 1
		charge.estimate = data[:refund]
		charge.discount = 0
		charge.amount = data[:refund]
		if charge.save
			note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs."
			note += data[:refund].to_s + " - Cancellation Refund.<br/>"
			self.notes += note
		end
		if data[:penalty] > 0
			charge = Charge.where(["booking_id = ? AND activity = 'cancellation_charge'", self.id]).first
			charge = Charge.new(booking_id: self.id, activity: 'cancellation_charge') if !charge
			charge.estimate = data[:penalty]
			charge.discount = 0
			charge.amount = data[:penalty]
			if charge.save
				note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs."
				note += data[:penalty].to_s + " - Cancellation Charge.<br/>"
				self.notes += note
			end
		end
		total = 0 - data[:refund] + data[:penalty]
		
		deposit = Charge.where(["booking_id = ? AND activity = 'security_deposit'", self.id]).first
		if deposit
			charge = Charge.where(["booking_id = ? AND activity = 'security_deposit_refund'", self.id]).first
			charge = Charge.new(booking_id: self.id, activity: 'security_deposit_refund') if !charge
			charge.estimate = deposit.amount
			charge.discount = 0
			charge.amount = deposit.amount
			charge.refund = 1
			if charge.save
				note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs."
				note += data[:penalty].to_s + " - Security Deposit Refund.<br/>"
				self.notes += note
			end
			#total -= deposit.amount.to_i
			out = Booking.find_by_id(self.id)
			#self.reload
			total = out.outstanding_without_deposit
			deposit = 0
			if total < 0
				amount = [out.security_amount.to_i, out.user.wallet_total_amount.to_i].min
				if self.hold
					deposit = amount if amount > 0
				else
					total -= amount if amount > 0
				end
			else
				amount = [out.security_amount.to_i, out.user.wallet_total_amount.to_i].min
				total -= amount if amount > 0
				if total < 0
					deposit = total.abs if self.hold
				else
					total = 0
					deposit = 0
				end
			end
			# if !self.hold
			# 	if self.insufficient_deposit || self.security_charge.nil?
			# 		amount = [self.security_amount.to_i, self.user.wallet_total_amount.to_i].min	
			# 		total -= amount if amount > 0
			# 	else
			# 		total = self.outstanding
			# 	end
			# end
		# elsif !self.hold && refunds.where(through: 'wallet').any?
		# 	make_payment_from_wallet(refunds.where(through: 'wallet').first.amount)
		end
		self.save(validate: false)
		BookingMailer.cancel(self.id,total.to_i.abs,deposit.to_i.abs).deliver
		sendsms('cancel', total.to_i.abs,deposit.to_i.abs) if Rails.env.production?
		return data
	end
	
	def do_charge(str, fare, action_text)
		if fare[:log] && fare[:total] > 0
			charge = Charge.new(booking_id: self.id, activity: action_text, estimate: 0, discount: 0, amount: 0)
			charge.hours = fare[:hours].round
			charge.billed_total_hours += fare[:hours].round
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
						charge.amount.to_s + " - Reschedule Refund." + self.starts_last.strftime(" %d/%m/%y %I:%M %p") + " : " + self.ends_last.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.starts.strftime(" %d/%m/%y %I:%M %p") + " : " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
					else
						charge.amount.to_s + " - Reschedule Charge." + self.starts_last.strftime(" %d/%m/%y %I:%M %p") + " : " + self.ends_last.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.starts.strftime(" %d/%m/%y %I:%M %p") + " : " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
					end
				when 'Extending' then charge.amount.to_s + " - Extension Charges." + self.ends_last.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
				when 'Shortening' then charge.amount.to_s + " - Shorten Refund." + self.ends_last.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
				end
				self.notes += note
			end
			# Trip modification charges
			if fare[:penalty] > 0
				charge = Charge.new(booking_id: self.id, activity: action_text.gsub('refund', 'charge'), estimate: 0, discount: 0, amount: 0)
				charge.hours = fare[:hours].round
				charge.billed_total_hours += fare[:hours].round
				charge.billed_discounted_hours += fare[:discounted_hours].round
				charge.billed_standard_hours += fare[:standard_hours].round
				charge.estimate += fare[:penalty]
				charge.discount += 0
				charge.amount += fare[:penalty]
				if charge.save
					note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs."
					note << case str
					when 'Early Return' then charge.amount.to_s + ' - Early Return Fee.' + self.ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.returned_at.strftime("%d/%m/%y %I:%M %p") + "<br/>"
					else charge.amount.to_s + " - Reschedule Fee." + self.starts_last.strftime(" %d/%m/%y %I:%M %p") + " : " + self.ends_last.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.starts_last.strftime(" %d/%m/%y %I:%M %p") + " : " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
					end
					self.notes += note
				end
			end
			return charge
		else
			note = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b>"
			note << case str
			when 'Early Return' then 'No Early Return Credits.' + self.ends.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.returned_at.strftime("%d/%m/%y %I:%M %p") + "<br/>"
			when 'Rescheduling' then 'No Reschedule Charges.' + self.starts_last.strftime(" %d/%m/%y %I:%M %p") + " : " + self.ends_last.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.starts_last.strftime(" %d/%m/%y %I:%M %p") + " : " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
			when 'Extending' then "No Extension Charges." + self.ends_last.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
			when 'Shortening' then "No Reschedule Refund." + self.ends_last.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
			end
			self.notes += note
			return nil
		end
	end
	
	def do_reschedule
		str = ''
		fare = self.get_fare
		return if self.starts == self.starts_last && self.ends == self.ends_last
		check = self.manage_inventory
		if check != 1
			BookingMailer.change_failed(self.id).deliver
			str = 'NA'
		else
			if self.starts != self.starts_last
				str = 'Rescheduling'
				if fare[:hours] > 0
					self.rescheduled = true
					if fare[:refund] > 0
						action_text = 'reschedule_refund'
					else
						action_text = 'reschedule_fee'
					end
				end
			elsif self.ends != self.ends_last
				if self.ends > self.ends_last
					action_text = 'extension_fee'
					str = 'Extending'
					self.extended = true
				else
					action_text = 'shortened_trip_refund'
					str = 'Shortening'
					self.shortened = true
				end
			end
			charge = self.do_charge(str, fare, action_text)
			self.save(validate: false)
			if fare[:hours] > 0 || str == 'Rescheduling'
				if charge
					if charge.refund == 1
						total = -1 * charge.amount.to_i
					else
						total = charge.amount.to_i
					end
					BookingMailer.change(self.id, total).deliver
					sendsms('change', total)
				else
					BookingMailer.change(self.id, 0).deliver
					sendsms('change', 0)
				end
			end
		end
		return [str, fare]
	end
	
	def do_return
		str = ''
		fare = self.get_fare
		return if self.returned_at.blank? || self.returned_at == self.returned_at_was
		# Manage Inventory
		if !self.returned_at_was.blank?
			if self.returned_at_was > self.ends
				self.manage_inventory(self.ends, self.returned_at_was, false)
			elsif self.returned_at_was < self.ends
				self.manage_inventory(self.car_id, self.returned_at_was, self.ends, true)
			end
		end
					
		if self.ends < self.returned_at
			action_text = 'early_return_refund'
			str = 'Early Return'
			self.early = true
			Inventory.release(self.cargroup_id, self.location_id, self.returned_at, self.ends)
		elsif self.ends > self.returned_at
			action_text = 'late_fee'
			str = 'Late Return'
			self.late = true
		end
		charge = self.do_charge(str, fare, action_text)
		self.save(validate: false)
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
	
	def get_fare
		return "Pricing#{self.pricing.version}".constantize.check(self)
	end
	
	def hold_security?
		self.hold == true
	end
	
	def link
		return "http://" + HOSTNAME + "/bookings/" + self.encoded_id
	end

	def make_payment_from_wallet(amount= security_amount, insufficient_flag=true)
    return unless self.wallet_security_payment.nil?
		amount = [amount.to_i, user.wallet_total_amount.to_i].min
		if (amount < security_amount) && insufficient_flag
			self.update_column(:insufficient_deposit,true) and return
		end 
		return if amount.to_i <= 0
		wpayment = Payment.create!(status: 1, booking_id: self.id, through: 'wallet', amount: (amount > self.pricing.mode::SECURITY) ? (self.pricing.mode::SECURITY) : amount)
		Wallet.create!(amount: amount, user_id: self.user_id, status: 1, credit: false, transferable: wpayment)
	end
	
	def manage_inventory
		check = 1
		cargroup = self.cargroup
		if self.car_id.blank?
			Inventory.connection.clear_query_cache
			ActiveRecord::Base.connection.execute("LOCK TABLES inventories WRITE")
			if !self.starts_last.blank? && (self.starts != self.starts_last || self.ends != self.ends_last)
				if self.starts > self.ends_last + cargroup.wait_period.minutes || self.ends < self.starts_last - cargroup.wait_period.minutes
					# Non Overlapping Reschedule
					check = Inventory.check(self.city_id, self.cargroup_id, self.location_id, (self.starts - cargroup.wait_period.minutes), (self.ends + cargroup.wait_period.minutes))
				elsif (self.starts != self.starts_last || self.ends != self.ends_last)
					# Overlapping Reschedule
					if self.starts < self.starts_last
						check = Inventory.check(self.city_id, self.cargroup_id, self.location_id, (self.starts - cargroup.wait_period.minutes), self.starts_last)
					end
					if self.ends > self.ends_last && check == 1
						check = Inventory.check(self.city_id, self.cargroup_id, self.location_id, self.ends_last, (self.ends + cargroup.wait_period.minutes))
					end
				end
				if check == 1
					Inventory.release(self.cargroup_id, self.location_id, self.starts_last, self.ends_last)
					Inventory.block(self.cargroup_id, self.location_id, self.starts, self.ends)
				end
			else
				if self.status < 9
					check = Inventory.check(self.city_id, self.cargroup_id, self.location_id, (self.starts - cargroup.wait_period.minutes), (self.ends + cargroup.wait_period.minutes))
					Inventory.block(self.cargroup_id, self.location_id, self.starts, self.ends) if check == 1
				else
					Inventory.release(self.cargroup_id, self.location_id, self.starts, self.ends)
				end
			end
			ActiveRecord::Base.connection.execute("UNLOCK TABLES")
		else
			check = self.car.manage_inventory(self.starts_last, self.ends_last, self.starts, self.ends, (self.status < 9))
		end
		return check
	end

	def kle_enabled
		#binding.pry
		if !self.location.kle_enabled.nil?
			#return (self.starts >= self.location.kle_enabled && Cargroup.find(self.actual_cargroup_id).kle)
			return (self.starts >= self.location.kle_enabled && Cargroup.find(self.cargroup_id).kle)
		else
			false
		end
	end
	
	def outstanding
		total = self.total_charges
		total -= self.total_payments
		total += self.total_refunds
		return total.to_i
	end

	def outstanding_with_security
		total = self.outstanding_without_deposit 
		total<=0 ? security_amount_remaining : (total + security_amount_remaining)
	end

	def outstanding_without_deposit
  		total = 0
		self.charges.each do |c|
			unless c.activity.include?('early_return') || c.activity.include?('security_deposit')
				if c.refund > 0
					total -= c.amount.to_i
				else
					total += c.amount.to_i
				end
			end
		end
		self.confirmed_payments.reject{|p| p.through.include?("wallet")}.each do |p|
			total -= p.amount.to_i
		end
		self.confirmed_refunds.each do |r|
			next if r.through == 'wallet_refund'
			total += r.amount.to_i if !r.through.include?('early_return')
		end
		return total.to_i	
  	end
	
	def outstanding_warning
		return "Please pay any outstanding amount by <b>#{(self.starts - CommonHelper::JIT_DEPOSIT_CANCEL.hours).strftime('%d/%m/%y %I:%M %p')}</b> or your booking will get <u>cancelled</u>."
	end

	# Check if a given interval overlaps this interval    
	def overlaps?(other)
		return false if other.nil?
		(starts - other.ends) * (other.starts - ends) >= 0
	end

	# Check if a given interval overlaps this interval    
	def wallet_overlaps?(other)
		return false if other.nil?
		((starts - CommonHelper::WALLET_FREEZE_START.hours) - (other.ends + CommonHelper::WALLET_FREEZE_END.hours)) * ((other.starts- CommonHelper::WALLET_FREEZE_START.hours) - (ends + CommonHelper::WALLET_FREEZE_END.hours))>= 0
	end

	def refund_amount
		total = 0
		self.charges.each do |c|
			if !c.activity.include?('charge') && !c.activity.include?('deposit')
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
			if !a.activity.include?('security') && 
				!a.activity.include?('early_return') && 
				!['vehicle_damage_fee', 'fuel_refund', 'andhra_permit_refund'].include?(a.activity)
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
	
	def revenue_with_deposit
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
		book.update_columns(total_fare: book.revenue, total: book.revenue_with_deposit, balance: book.outstanding)
		#Utilization.manage(id)
	end

	def security_amount
		pricing.mode::SECURITY rescue 0
	end

	def security_amount_deferred?
		pricing.mode::SECURITY > 0 && security_amount_remaining > 0
	end

	def security_amount_remaining
		return 0 if ((status > 1) || wallet_security_payment.present?)
		count = Booking.select(:id).where('user_id = ? and starts = ? and created_at < ? and status < 8 and status > 0', self.user_id, self.starts, self.created_at.blank? ? Time.now : self.created_at).count # for exactly overlaping booking
		amount = security_amount*(count+1) - user.wallet_available_on_time(self.starts.advance(hours: -CommonHelper::WALLET_FREEZE_START), self)
		amount = (amount < 0) ? 0 : amount
		[amount, security_amount].min
	end

	def security_charge
		charges.where(activity: 'security_deposit', :active=>true).first
	end
	
	def security_refund_charge
		charges.where(activity: 'security_deposit_refund', :active=>true).first
	end
	
	def wallet_security_payment
		payments.where(through: 'wallet', :status=>1).first
	end

	def sendsms(action, amount,deposit = 0)
		message =  case action 
		when 'change' then "Zoom booking (#{self.confirmation_key}) is changed. #{self.cargroup.display_name} from #{self.starts.strftime('%I:%M %p, %d %b')} till #{self.ends.strftime('%I:%M %p, %d %b')} at #{self.location.shortname}. "
		when 'cancel' then "Hi! Your Zoomcar booking (#{self.confirmation_key}) has been cancelled."
		end
		if action == 'cancel'
			if amount > 0 && deposit > 0
				message << "We have initiated a refund of Rs.#{amount.to_i.abs}, it should reach your account in 5 business days. Rs.#{deposit.to_i.abs} of your deposit has been moved to your Zoomcar Wallet."
			elsif amount == 0 && deposit > 0 
				message <<"Rs.#{deposit.to_i.abs} of your deposit has been moved to your Zoomcar Wallet"
			elsif amount > 0 && deposit == 0
				message << "We have initiated a refund of Rs.#{amount.to_i.abs}."
			elsif amount == 0 && deposit == 0
				message<<"All charges were covered by the Security Deposit, it should reach your account in 5 business days."
			end
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
		message << "#{self.city.contact_phone} : Zoom Support." if action != 'cancel'
		#SmsSender.perform_async(self.user_mobile, message, self.id) if Rails.env.production?
		SmsTask::message_exotel(self.user_mobile, message, self.id)
	end
	
	def set_fare
		tmp = self.get_fare
		self.total_fare = tmp[:total]
		if self.defer_deposit.blank?
			self.total = tmp[:total] + pricing.mode::SECURITY
		else
			self.total = tmp[:total]
		end
		self.estimate = tmp[:estimate]
		self.discount = tmp[:discount]
		self.hours = tmp[:hours]
		self.normal_hours = tmp[:standard_hours]
		self.discounted_hours = tmp[:discounted_hours]
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
			elsif self.starts > Time.zone.now + 24.hours
				return 'future'
			elsif self.starts > Time.zone.now
				return 'near'
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
			when 8 then 'Settled'
			when 9 then 'No Show'
			when 10 then 'Cancelled'
			when 12 then 'Auto Cancelled'
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
			when 8 then 'Settled'
			when 9 then 'No Show'
			when 10 then 'Cancelled'
			when 12 then 'Auto Cancelled'
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
		when 8 then 'Settled'
		when 9 then 'No Show'
		when 10 then 'Cancelled'
		when 12 then 'Auto Cancelled'
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

	def user_details(user)
		self.user_id = user.id
		self.user_name = user.name
		self.user_email = user.email
		self.user_mobile = user.phone
	end
	
	def wallet_impact
		{starts: ([Time.now, starts-CommonHelper::WALLET_FREEZE_START.hours].max),
		 booking: self,
		 amount: hold_security? ? 0 : -security_amount,
		 ends: ([ends+CommonHelper::WALLET_FREEZE_END.hours, Time.now+CommonHelper::WALLET_SNAPSHOT.days].min)}
	end

	protected
	
	def after_create_tasks
		charge                         = Charge.new(:booking_id => self.id, :activity => 'booking_fee')
		charge.hours                   = self.hours
		charge.billed_total_hours      = self.hours
		charge.billed_discounted_hours = self.discounted_hours
		charge.billed_standard_hours   = self.normal_hours
		charge.estimate                = self.estimate
		charge.discount                = self.discount
		charge.amount                  = self.total_fare
		charge.save
		self.confirmation_key = self.encoded_id.upcase
		self.hold = true
		self.save(validate: false)
	end

	def after_save_tasks
	end
	
	def before_create_tasks
	end
	
	def before_save_tasks
		self.actual_cargroup_id = self.cargroup_id if self.cargroup_id_changed?
		if self.id.blank?
			setup
			set_fare
			self.notes = "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs." + self.total.to_i.to_s + " - Booking Charges."
			self.notes += self.starts.strftime(" %d/%m/%y %I:%M %p") + " -> " + self.ends.strftime("%d/%m/%y %I:%M %p") + "<br/>"
		else
			self.total = self.revenue
			self.balance = self.outstanding
		end
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

# == Schema Information
#
# Table name: bookings
#
#  id                       :integer          not null, primary key
#  car_id                   :integer
#  location_id              :integer
#  user_id                  :integer
#  booked_by                :integer
#  cancelled_by             :integer
#  comment                  :string(255)
#  days                     :integer
#  hours                    :integer
#  estimate                 :decimal(8, 2)
#  discount                 :decimal(8, 2)
#  total                    :decimal(8, 2)
#  starts                   :datetime
#  ends                     :datetime
#  cancelled_at             :datetime
#  returned_at              :datetime
#  ip                       :string(255)
#  status                   :integer          default(0)
#  jsi                      :string(10)
#  user_name                :string(255)
#  user_email               :string(255)
#  user_mobile              :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  start_km                 :string(10)
#  end_km                   :string(10)
#  normal_days              :integer          default(0)
#  normal_hours             :integer          default(0)
#  discounted_days          :integer          default(0)
#  discounted_hours         :integer          default(0)
#  actual_starts            :datetime
#  actual_ends              :datetime
#  last_starts              :datetime
#  last_ends                :datetime
#  early                    :boolean          default(FALSE)
#  late                     :boolean          default(FALSE)
#  extended                 :boolean          default(FALSE)
#  rescheduled              :boolean          default(FALSE)
#  fuel_starts              :integer
#  fuel_ends                :integer
#  daily_fare               :integer
#  hourly_fare              :integer
#  hourly_km_limit          :integer
#  daily_km_limit           :integer
#  excess_kms               :integer          default(0)
#  notes                    :text
#  cargroup_id              :integer
#  fleet_id_start           :integer
#  fleet_id_end             :integer
#  individual_start         :integer
#  individual_end           :integer
#  transport                :integer
#  unblocks                 :datetime
#  outstation               :boolean          default(FALSE)
#  checkout                 :datetime
#  confirmation_key         :string(20)
#  balance                  :integer
#  ref_initial              :string(255)
#  ref_immediate            :string(255)
#  promo                    :string(255)
#  credit_status            :integer          default(0)
#  offer_id                 :integer
#  pricing_id               :integer
#  corporate_id             :integer
#  city_id                  :integer
#  pricing_mode             :string(2)
#  medium                   :string(12)
#  shortened                :boolean          default(FALSE)
#  total_fare               :integer
#  deposit_status           :integer          default(0)
#  carry                    :boolean          default(FALSE)
#  hold                     :boolean          default(FALSE)
#  release_payment          :boolean          default(FALSE)
#  settled                  :boolean          default(FALSE)
#  actual_cargroup_id       :integer
#  actual_cargroup_id_count :integer          default(0)
#  car_id_count             :integer          default(0)
#  cargroup_id_count        :integer          default(0)
#  ends_count               :integer          default(0)
#  end_km_count             :integer          default(0)
#  location_id_count        :integer          default(0)
#  returned_at_count        :integer          default(0)
#  starts_count             :integer          default(0)
#  start_km_count           :integer          default(0)
#  defer_deposit            :boolean
#  insufficient_deposit     :boolean          default(FALSE)
#  fleet_checklist_by       :integer
#  start_checklist_by       :integer
#  end_checklist_by         :integer
#
# Indexes
#
#  index_bookings_on_car_id            (car_id)
#  index_bookings_on_cargroup_id       (cargroup_id)
#  index_bookings_on_confirmation_key  (confirmation_key)
#  index_bookings_on_ends              (ends)
#  index_bookings_on_jsi               (jsi)
#  index_bookings_on_location_id       (location_id)
#  index_bookings_on_ref_immediate     (ref_immediate)
#  index_bookings_on_ref_initial       (ref_initial)
#  index_bookings_on_starts            (starts)
#  index_bookings_on_unblocks          (unblocks)
#  index_bookings_on_user_email        (user_email)
#  index_bookings_on_user_id           (user_id)
#  index_bookings_on_user_mobile       (user_mobile)
#
