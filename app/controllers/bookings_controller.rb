class BookingsController < ApplicationController
	
	before_filter :check_booking, :only => [:complete, :dopayment, :invoice, :payment, :payments, :show]
	
	def complete
		render layout: 'plain'
	end
	
	def dopayment
		session[:booking_id] = @booking.encoded_id
		redirect_to "/bookings/payment"
	end
	
	def index
		render layout: 'users'
	end
	
	def invoice
		render layout: 'plain'
	end
	
	def payment
		@payment = @booking.check_payment
		if @payment
			render :layout => 'plain'
		else
			flash[:notice] = "Booking is already paid for full, no need for a new transaction."
      redirect_to "/bookings/" + @booking.encoded_id and return
    end
	end
	
	def payments
		render layout: 'users'
	end
	
	def payu
		if !params[:status].blank? && 
			!params[:key].blank? && params[:key] == PAYU_KEY &&
			!params[:txnid].blank? && 
			!params[:amount].blank? && 
			!params[:productinfo].blank? && 
			!params[:firstname].blank? && 
			!params[:email].blank? && 
			!params[:hash].blank?
			str,id = CommonHelper.decode(params[:txnid])
			if !str.blank? && str == 'payment'
				@payment = Payment.find(id)
				if @payment
					@booking = @payment.booking
					hash = PAYU_SALT + "|" + 
						params[:status] + "|||||||||||" + 
						@booking.user_email + "|" + 
						@booking.user_name + "|" + 
						params[:productinfo] + "|" + 
						params[:amount] + "|" + 
						@payment.encoded_id.downcase + "|" + 
						PAYU_KEY
					if params[:amount].to_i == @payment.amount.to_i && 
						params[:firstname] == @booking.user_name && 
						params[:email] == @booking.user_email && 
						Digest::SHA512.hexdigest(hash) == params[:hash]
						@payment.status = case params[:status].downcase
						when 'success' then 1
						when 'failure' then 2
						when 'pending' then 3
						end
						if !params[:mode].blank?
							@payment.mode = case params[:mode].downcase
							when 'cc' then 0
							when 'dc' then 1
							end
						end
						@payment.key = params[:mihpayid] if !params[:mihpayid].blank?
						@payment.notes = ''
						@payment.notes << "<b>ERROR : </b>" + params[:error] + "<br/>" if !params[:error].blank?
						@payment.notes << "<b>ERROR MESSAGE : </b>" + params[:error_Message] + "<br/>" if !params[:error_Message].blank?
						@payment.notes << "<b>PG TYPE : </b>" + params['PG_TYPE'] + "<br/>" if !params['PG_TYPE'].blank?
						@payment.notes << "<b>Bank Ref Num : </b>" + params[:bank_ref_num] + "<br/>" if !params[:bank_ref_num].blank?
						@payment.notes << "<b>Unmapped Status : </b>" + params[:unmappedstatus] + "<br/>" if !params[:unmappedstatus].blank?
						@payment.notes << "<b>Name On Card : </b>" + params[:name_on_card] + "<br/>" if !params[:name_on_card].blank?
						@payment.notes << "<b>Card Number : </b>" + params[:cardnum] + "<br/>" if !params[:cardnum].blank?
						@payment.save(:validate => false)
					else
						@payment = nil
					end
				end
			end
		end
		if @payment
			if @payment.status == 1
        flash[:notice] = "Thanks for the payment. Please continue."
      elsif @payment.status == 3
        flash[:error] = "Your transaction is subject to manual approval by the payment gateway. We will keep you updated about the same through email."
      else
        flash[:error] = "Your transaction has failed. Please do a fresh transaction."
      end
      session[:booking_id] = @booking.encoded_id
      logger.debug "BOOKING ID : #{session[:booking_id]}"
      redirect_to "/bookings/complete"
		else
			exception
		end
	end
	
	def search
		@meta_title = "Zoom - Car Hire in Bangalore"
		@meta_description = "Enjoy the Freedom of Four Wheels with self-drive car hire by the hour or by the day. Now in Bangalore!"
		@meta_keywords = "car hire, car rental, car rent, car sharing, car share, shared car, car club, rental car, car-sharing, hire car, renting a car, bangalore, bangalore car hire, bangalore car rental, bangalore car rent, bangalore car sharing, bangalore car share, bangalore car club, bangalore rental car, bangalore car-sharing, bangalore hire car, bagalore renting a car, India, Indian, Indian car-sharing, India car-sharing, Indian car-share, India car-share, India car club, Indian car club, India car sharing, Indian car, Zoomcar, Zoom car, travel india, travel bangalore, explore india, explore bangalore, travel, explore, self-drive, self drive, self-drive bangalore, self drive bangalore"
		@canonical = "https://www.zoomcar.in/search"
	end
	
	def show
		flash.keep
		render layout: 'users'
	end
	
	def widget
		render json: {html: render_to_string('widget.haml')}
	end
	
	private
	
	def check_booking
		id = nil
		if !session[:booking_id].blank?
			id = session[:booking_id]
			session.delete(:booking_id)
		elsif !params[:id].blank?
			id = params[:id]
		end
		if id
			str,id = CommonHelper.decode(id)
			if !str.blank? && str == 'booking'
				@booking = Booking.find(id)
			else
				render_404
			end
		else
			render_404
		end
	end
	
end
