class Payment < ActiveRecord::Base
	
	belongs_to :booking
	has_one :wallet, as: :transferable
    has_one :activity, as: :transferred_via

	validates :booking_id, :through, :amount, presence: true
	#validates :through, uniqueness: {scope: [:booking_id, :key]}
	
	default_scope {where('(status < 5)')}
	
	after_save :after_save_tasks

	pg = {1 => 'axis', 2 => 'hdfc', 3 => 'icici', 4 => 'citi', 5 => 'amex', 11 => 'ebs', 12 => 'payu', 20 => 'paypal', 201 => 'hdfc_ivr'}
	
	def change_mode(params)
		if !params['mode'].blank?
			mode = case params['mode'].downcase
			when 'cc' then 0
			when 'dc' then 1
			when 'nb' then 2
			else nil
			end
			self.update_column(:mode, mode) if mode
		end
	end
	
	def change_status(params)
		if !params['status'].blank? && !params['amt'].blank?
			if params['amt'].to_i == self.amount.to_i
				sta = case params['status'].downcase
				when 'success' then 1
				when 'failure' then 2
				when 'pending' then 3
				else 3
				end
				if self.status != sta
					self.status = sta
					if !params['mode'].blank?
						self.mode = case params['mode'].downcase
						when 'cc' then 0
						when 'dc' then 1
						when 'nb' then 2
						end
					end
					self.key = params['mihpayid'] if !params['mihpayid'].blank?
					self.through = 'payu'
					self.notes = ''
					self.notes << "<b>ERROR : </b>" + params['error'] + "<br/>" if !params['error'].blank?
					self.notes << "<b>ERROR MESSAGE : </b>" + params['error_Message'] + "<br/>" if !params['error_Message'].blank?
					self.notes << "<b>PG TYPE : </b>" + params['PG_TYPE'] + "<br/>" if !params['PG_TYPE'].blank?
					self.notes << "<b>Bank Ref Num : </b>" + params['bank_ref_num'] + "<br/>" if !params['bank_ref_num'].blank?
					self.notes << "<b>Unmapped Status : </b>" + params['unmappedstatus'] + "<br/>" if !params['unmappedstatus'].blank?
					self.notes << "<b>Name On Card : </b>" + params['name_on_card'] + "<br/>" if !params['name_on_card'].blank?
					self.notes << "<b>Card Number : </b>" + params['cardnum'] + "<br/>" if !params['cardnum'].blank?
					self.save(:validate => false)
				end
			end
		end
	end

	def change_status_pmt(params, through)
		if through == 'juspay'
			self.update_status_juspay(params)
		end
	end
	
	def encoded_id
		CommonHelper.encode('payment', self.id)
	end
	
	def mode_text
		case self.mode
		when 0 then 'Credit Card'
		when 1 then 'Debit Card'
		end
	end
	
	def self.check_mismatch
		count = 0
		Payment.find_by_sql("SELECT p.* FROM payments p 
			INNER JOIN bookings b ON b.id = p.booking_id 
			WHERE p.through IN ('citruspay', 'juspay', 'payu') AND p.status = 1 AND b.status = 0 AND p.created_at < '#{(Time.now - 30.minutes).to_s(:db)}'").each do |p|
			p.update_column(:status, 0)
			p.status = 1
			p.save
			count += 1
		end
		return count
	end
	
	def self.check_mode
		Payment.find(:all, :conditions => "status = 1 AND through IN ('citruspay', juspay', 'payu') AND mode IS NULL").each do |p|
			resp = Payu.check_status(p.encoded_id)
			if resp && resp['status'] == 1
      	resp['transaction_details'].each do |k,v|
	    		str,id = CommonHelper.decode(k.downcase)
	    		if !str.blank? && str == 'payment'
						payment = Payment.find(id)
						payment.change_mode(v) if payment
					end
				end
      end
		end
	end
	
	def self.check_status
    Payment.unscoped.find(:all, :conditions => ["through IN ('juspay', 'payu') AND (status is NULL or status != 1) AND created_at >= ? AND created_at < ?", Time.now - 2.hours, Time.now - 15.minutes]).each do |p|
			resp = Juspay.check_status(p.encoded_id)
			if resp && resp['status_id'].to_i < 40
				str,id = CommonHelper.decode(resp['order_id'].downcase)
				if str.present? && str == 'payment'
					payment = Payment.find(id)
					payment.change_status_pmt(resp, 'juspay') if payment
				end
			else
				resp = Payu.check_status(p.encoded_id)
				if resp && resp['status'] == 1
	      	resp['transaction_details'].each do |k,v|
		    		str,id = CommonHelper.decode(k.downcase)
		    		if !str.blank? && str == 'payment'
							payment = Payment.find(id)
							payment.change_status(v) if payment
						end
					end
				end
      end
		end
		Payment.check_mismatch
		#Payment.check_mode
	end
	
	def self.do_create(params)
		if !params['status'].blank? && 
			!params['key'].blank? && params['key'] == PAYU_KEY &&
			!params['txnid'].blank? && 
			!params['amount'].blank? && 
			!params['productinfo'].blank? && 
			!params['firstname'].blank? && 
			!params['email'].blank? && 
			!params['hash'].blank?
			str,id = CommonHelper.decode(params['txnid'])
			if !str.blank? && str == 'payment'
				payment = Payment.find(id)
				if payment
					booking = payment.booking
					if params['additionalCharges'].present?
						hash = params['additionalCharges'] + "|"
					else
						hash = ""
					end
					hash += PAYU_SALT + "|" + 
						params['status'] + "|||||||||||" + 
						booking.user.email + "|" +
						booking.user.name.strip + "|" +
						params['productinfo'] + "|" + 
						params['amount'] + "|" + 
						payment.encoded_id.downcase + "|" + 
						PAYU_KEY
					if params['amount'].to_i == payment.amount.to_i && 
						params['firstname'] == booking.user.name.strip &&
						params['email'] == booking.user.email &&
						Digest::SHA512.hexdigest(hash) == params['hash']
						payment.status = case params['status'].downcase
						when 'success' then 1
						when 'failure' then 2
						when 'pending' then 3
						else 3
						end
						if !params['mode'].blank?
							payment.mode = case params['mode'].downcase
							when 'cc' then 0
							when 'dc' then 1
							end
						end
						payment.through = 'payu'
						payment.key = params['mihpayid'] if !params['mihpayid'].blank?
						payment.notes = ''
						payment.notes << "<b>ERROR : </b>" + params['error'] + "<br/>" if !params['error'].blank?
						payment.notes << "<b>ERROR MESSAGE : </b>" + params['error_Message'] + "<br/>" if !params['error_Message'].blank?
						payment.notes << "<b>PG TYPE : </b>" + params['PG_TYPE'] + "<br/>" if !params['PG_TYPE'].blank?
						payment.notes << "<b>Bank Ref Num : </b>" + params['bank_ref_num'] + "<br/>" if !params['bank_ref_num'].blank?
						payment.notes << "<b>Unmapped Status : </b>" + params['unmappedstatus'] + "<br/>" if !params['unmappedstatus'].blank?
						payment.notes << "<b>Name On Card : </b>" + params['name_on_card'] + "<br/>" if !params['name_on_card'].blank?
						payment.notes << "<b>Card Number : </b>" + params['cardnum'] + "<br/>" if !params['cardnum'].blank?
						payment.save(:validate => false)
						return payment
					end
				end
			end
		end
		return nil
	end
	
	def self.juspay_create(params)
		if !params['order_id'].blank? && !params['status'].blank? && !params['status_id'].blank?
			str, id = CommonHelper.decode(params['order_id'])
			if !str.blank? && str == 'payment'
				payment = Payment.find(id)
				if payment
					booking = payment.booking
					response = Juspay.check_status(params['order_id'])
					if response['amount'] == payment.amount.to_i && params['status'].downcase == response['status'].downcase && response['customer_email'] == booking.user.email && response['customer_id'] == booking.user.encoded_id
						payment.update_status_juspay(response)
						return payment
					end
				end
			end
		end
		return nil
	end

	def status_text
		case self.status
		when 0 then 'Initiated'
		when 1 then 'Success'
		when 2 then 'Failed'
		when 3 then 'Pending'
		else 3
		end
	end
	
	def through_text
		return self.through.capitalize
	end
	
	def self.update(id, dep)
		str,id = CommonHelper.decode(id.downcase)
		payment = Payment.find(id)
		booking = Booking.find(payment.booking_id)
		pricing = booking.pricing
		if dep == 'true'
			payment.amount += pricing.mode::SECURITY
      booking.update_column(:defer_deposit, false)
		else
			payment.amount -= pricing.mode::SECURITY
      booking.update_column(:defer_deposit, true)
		end
		booking.save!
		data = { order_id: payment.encoded_id, amount: payment.amount }
		response = Juspay.update_order(data)
		if(response['status'].downcase == 'new')
			payment.update_attribute(:amount, payment.amount)
			hash = PAYU_KEY + "|" + payment.encoded_id + "|" + payment.amount.to_i.to_s + "|" + booking.cargroup.display_name + "|" + booking.user.name.strip + "|" + booking.user.email + "|||||||||||" + PAYU_SALT
			json_resp = {:status=> 'success', :msg => "updated amount", :amt => payment.amount.to_i, :hash => Digest::SHA512.hexdigest(hash)}
		else
			json_resp = {:status=> 'error', :msg => "Juspay error", :amt => payment.amount.to_i}
		end
	end

		def update_status_juspay(params)
		if params['amount'] == self.amount.to_i
			self.status = case params['status'].downcase
			when 'charged' then 1
			when 'authentication_failed' then 2
			when 'authorization_failed' then 2
			when 'juspay_declined' then 2
			when 'pending_vbv' then 3
			when 'started' then 3
			else 3
			end
			self.through = 'juspay'
			self.key = params['order_id'] if !params['order_id'].blank?
			self.notes = ''
			if params['status_id'] == 21
				if params['card'].present?
					self.mode = case params['card']['card_type'].downcase
					when 'credit' then 0
					when 'debit' then 1
					end
				end
				self.notes << "<b>ERROR : </b>" + params['payment_gateway_response']['resp_code'] + "<br/>" if !params['payment_gateway_response']['resp_code'].blank?
				self.notes << "<b>ERROR MESSAGE : </b>" + params['payment_gateway_response']['resp_message'] + "<br/>" if !params['payment_gateway_response']['resp_message'].blank?
				self.notes << "<b>Gateway ID : </b>" + params['gateway_id'].to_s + "<br/>" if !params['gateway_id'].blank?
				self.notes << "<b>Bank RRN : </b>" + params['payment_gateway_response']['rrn'] + "<br/>" if !params['payment_gateway_response']['rrn'].blank?
				self.notes << "<b>Auth Id Code : </b>" + params['payment_gateway_response']['auth_id_code'] + "<br/>" if !params['payment_gateway_response']['auth_id_code'].blank?
				self.notes << "<b>Name On Card : </b>" + params['card']['name_on_card'] + "<br/>" if !params['card']['name_on_card'].blank?
				self.notes << "<b>Card ISIN : </b>" + params['card']['card_isin'] + "<br/>" if !params['card']['card_isin'].blank?
				self.notes << "<b>Card Last 4 digits : </b>" + params['card']['last_four_digits'] + "<br/>" if !params['card']['last_four_digits'].blank?
			end
			self.save(:validate => false)
		end
	end

	# Skips callback if the payment is Offer/Credit related and its within 24 hours
  # Author:: Rohit
  # Date:: 27/02/2015
  #
	def credit_offer_payment_with_in_defered_time?
		# return false if booking is > 24 hours period or its a non credit / non offer payment.
		return false if self.booking.defer_allowed? || ['credits','dummy'].exclude?(self.through.to_s)
		# Test for two conditions
		# Condition 1: User has wallet amount present in this account.
		return true if (self.booking.user.wallet_total_amount < CommonHelper::SECURITY_DEPOSIT)
		# Condition 2: Payment is fullfilled by Credit or offer used.
		return true if self.booking.outstanding > 0
		false
	end

	protected
	
	def after_save_tasks
		# skip callbaks for credit/offers payments with in 24 hours
		return if credit_offer_payment_with_in_defered_time?

		if self.status_changed? && self.status == 1 
			b = self.booking
			b.valid?
			if b && b.outstanding_without_deposit<= 0
				old_status = b.status
				if b.status == 0
					b.carry = true if (self.amount > b.outstanding)
					if !b.car_id.blank?
						if b.promo.present? && b.promo.include?('SQUIRREL')
							# booking is deal booking
							str, id = CommonHelper.decode(b.promo[8, b.promo.length])
							if str == 'deal'
								deal = Deal.find_by(id: id)
								if !deal.sold_out
									b.status = 1
									deal.sold_out = true
									deal.booking_id = b.id
									deal.save!
								else
									# deal double booking
									b.status = 6
									# b.auto_cancel = true
									# b.valid?
									# b.do_cancellation
								end
							end
						else
							b.status = 1
						end
					elsif b.manage_inventory == 1
						b.status = 1
					else
						Inventory.block(b.cargroup_id, b.location_id, b.starts, b.ends)
						b.status = 6
					end
					#BookingMailer.payment(b.id).deliver
					#SmsSender.perform_async(b.user.phone, "Zoomcar booking (#{b.confirmation_key}) is confirmed. #{b.cargroup.display_name} from #{b.starts.strftime('%I:%M %p, %d %b')} till #{b.ends.strftime('%I:%M %p, %d %b')} at #{b.location.shortname}. #{b.city.contact_phone} : Zoomcar Support.", b.id)
					# if !b.location.kle_enabled.nil?
					# 	if (b.created_at < b.location.kle_enabled && b.starts >= b.location.kle_enabled) && (b.starts.to_i - b.created_at.to_i) < 86400 && b.kle_enabled
					# 		####SEND EMAIL#####
					# 		BookingMailer.kle_mail(b.id).deliver
					# 		Email.create(activity: 'Userprepardness_confirm',booking_id: b.id,user_id: b.user_id)
					# 	end
					# 	if (b.created_at < b.location.kle_enabled && b.starts > b.location.kle_enabled) && (b.starts.to_i - b.created_at.to_i) < 604800 && (b.starts.to_i - b.created_at.to_i) > 108000 && b.kle_enabled
					# 		####SEND EMAIL#####
					# 		BookingMailer.kle_mail(b.id).deliver
					# 		Email.create(activity: 'Userprepardness_confirm',booking_id: b.id,user_id: b.user_id)
					# 	end
					# 	if b.kle_enabled && b.created_at >= b.location.kle_enabled
					# 		BookingMailer.kle_mail(b.id).deliver
					# 		Email.create(activity: 'Userprepardness_confirm',booking_id: b.id,user_id: b.user_id)
					# 	end
					# end
					SmsTask::message_exotel(b.user.phone, "Zoomcar booking (#{b.confirmation_key}) is confirmed. #{b.cargroup.display_name} from #{b.starts.strftime('%I:%M %p, %d %b')} till #{b.ends.strftime('%I:%M %p, %d %b')} at #{b.location.shortname}. #{b.city.contact_phone} : Zoomcar Support.", b.id)
				end
				b.deposit_status = 2 if b.deposit_status == 1
				b.notes += "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs." + self.amount.to_s + " - Payment Received through <u>" + self.through_text + "</u>.<br/>"
				b.save(:validate => false)
				Booking.recalculate(b.id)
        activities_params = {user_id: b.user_id, booking_id: b.id, transferred_via: self}
        if ['citruspay', 'payu', 'juspay'].include?(self.through) && Refund.where("booking_id = ? AND created_at > ? and through = 'wallet'", b.id, self.created_at).empty? #TODO - move PG array to CommonHelper
					wallet_amount = (b.outstanding_without_deposit + self.amount)>=0 ? b.outstanding_without_deposit.abs : self.amount
					if wallet_amount != 0 && b.wallet_security_payment.nil?
						b.add_security_deposit_to_wallet(wallet_amount)
            extra_params = {activity: Activity::ACTIVITIES[:security_deposit_paid], amount: wallet_amount}
            log_activity(activities_params.merge(extra_params))
						self.update_column(:deposit_available_for_refund, wallet_amount)
						self.update_column(:deposit_paid, wallet_amount)
					end
					if !b.defer_payment_allowed?
						b.add_security_deposit_charge
					end
					if !b.defer_payment_allowed? && b.wallet_security_payment.nil?
						b.user.calculate_wallet_total_amount
						b.update_column(:insufficient_deposit, false)
						b.make_payment_from_wallet
					end
        end
        if b.defer_deposit?
          activity_obj = Activity.where('booking_id = ? and activity = ?',b.id,Activity::ACTIVITIES[:defer_deposit]).first
          if activity_obj.nil?
            activities_params.delete(:amount) if !activities_params[:amount].nil?
            activities_params[:activity] = Activity::ACTIVITIES[:defer_deposit]
            log_activity(activities_params)
          end
        end
				BookingMailer.payment(b.id).deliver if old_status==0
			end
		end
	end

  private

  def log_activity(params)
    Activity.create_activity(params)
  end
	
end

# == Schema Information
#
# Table name: payments
#
#  id                           :integer          not null, primary key
#  booking_id                   :integer
#  status                       :integer          default(0)
#  through                      :string(20)
#  key                          :string(255)
#  notes                        :text
#  amount                       :decimal(8, 2)
#  created_at                   :datetime
#  updated_at                   :datetime
#  mode                         :integer
#  qb_id                        :integer
#  refunded_amount              :integer          default(0)
#  deposit_available_for_refund :integer          default(0)
#  deposit_paid                 :integer          default(0)
#  rrn                          :string(255)
#  auth_id                      :string(255)
#
# Indexes
#
#  index_payments_on_booking_id  (booking_id)
#  index_payments_on_key         (key)
#
