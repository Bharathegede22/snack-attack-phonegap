class Payment < ActiveRecord::Base
	
	belongs_to :booking
	has_one :wallet, as: :transferable

	validates :booking_id, :through, :amount, presence: true
	#validates :through, uniqueness: {scope: [:booking_id, :key]}
	
	default_scope {where('(status < 5)')}
	
	after_save :after_save_tasks
	
	def change_status(params)
		if !params['status'].blank? && !params['amt'].blank?
			if params['amt'].to_i == self.amount.to_i
				sta = case params['status'].downcase
				when 'success' then 1
				when 'failure' then 2
				when 'pending' then 3
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
			WHERE p.through = 'payu' AND p.status = 1 AND b.status = 0 AND p.created_at < '#{(Time.now - 30.minutes).to_s(:db)}'").each do |p|
			p.save
			count += 1
		end
		return count
	end
	
	def self.check_status
		Payment.find(:all, :conditions => ["status != 1 AND created_at >= ? AND created_at < ?", Time.now - 1.hours, Time.now - 15.minutes]).each do |p|
			Payu.check_status(p.encoded_id)
		end
		Payment.check_mismatch
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
					booking.user_email = 'amit@zoomcar.in' if HOSTNAME != 'www.zoomcar.in'
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
			b.valid?
			if b && b.outstanding <= 0
				if b.status == 0
					if !b.car_id.blank?
						b.status = 1
					elsif b.manage_inventory == 1
						b.status = 1
					else
						Inventory.block(b.cargroup_id, b.location_id, b.starts, b.ends)
						b.status = 6
					end
					BookingMailer.payment(b.id).deliver
					if Rails.env.production?
						SmsSender.perform_async(b.user_mobile, "Zoom booking (#{b.confirmation_key}) is confirmed. #{b.cargroup.display_name} from #{b.starts.strftime('%I:%M %p, %d %b')} till #{b.ends.strftime('%I:%M %p, %d %b')} at #{b.location.shortname}. #{b.city.contact_phone} : Zoom Support.", b.id)
					end
				end
				b.deposit_status = 2 if b.deposit_status == 1
				b.notes += "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs." + self.amount.to_s + " - Payment Received through <u>" + self.through_text + "</u>.<br/>"
				b.save(:validate => false)
				Booking.recalculate(b.id)
			end
			b.add_security_deposit_to_wallet if !b.security_amount_deferred? && b.outstanding==0
		end
	end
	
end
