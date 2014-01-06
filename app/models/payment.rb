class Payment < ActiveRecord::Base
	
	belongs_to :booking
	
	validates :booking_id, :through, :amount, presence: true
	#validates :through, uniqueness: {scope: [:booking_id, :key]}
	
	after_save :after_save_tasks
	
	def encoded_id
		CommonHelper.encode('payment', self.id)
	end
	
	def mode_text
		case self.mode
		when 0 then 'Credit Card'
		when 1 then 'Debit Card'
		end
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
					hash = PAYU_SALT + "|" + 
						params['status'] + "|||||||||||" + 
						booking.user_email + "|" + 
						booking.user_name + "|" + 
						params['productinfo'] + "|" + 
						params['amount'] + "|" + 
						payment.encoded_id.downcase + "|" + 
						PAYU_KEY
					if params['amount'].to_i == payment.amount.to_i && 
						params['firstname'] == booking.user_name.strip && 
						params['email'] == booking.user_email && 
						Digest::SHA512.hexdigest(hash) == params['hash']
						payment.status = case params['status'].downcase
						when 'success' then 1
						when 'failure' then 2
						when 'pending' then 3
						end
						if !params['mode'].blank?
							payment.mode = case params['mode'].downcase
							when 'cc' then 0
							when 'dc' then 1
							end
						end
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
	
	def status_text
		case self.status
		when 0 then 'Initiated'
		when 1 then 'Success'
		when 2 then 'Failed'
		when 3 then 'Pending'
		end
	end
	
	def through_text
		return self.through.capitalize
	end
	
	protected
	
	def after_save_tasks
		if self.status == 1
			b = self.booking
			if b
				if b.status == 0
					if !b.car_id.blank?
						b.status = 1
					elsif Inventory.block(b.cargroup_id, b.location_id, b.starts, b.ends) == 1
						b.status = 1
					else
						b.status = 6
					end
					BookingMailer.payment(b).deliver
				end
				b.notes += "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs." + self.amount.to_s + " - Payment Received through <u>" + self.through_text + "</u>.<br/>"
				b.save(:validate => false)
			end
		end
	end
	
end
