class BookingsController < ApplicationController
	
	before_filter :check_booking, :only => [:invoice, :payment, :show]
	
	def index
		render layout: 'users'
	end
	
	def invoice
		render layout: 'plain'
	end
	
	def payment
		@payment = @booking.new_payment
		if @payment
			render :layout => nil
		else
			flash[:notice] = "Booking is already paid for full, no need for a new transaction."
      redirect_to "/bookings/" + @booking.encoded_id and return
    end
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
					booking = @payment.booking
					hash = PAYU_SALT + "|" + 
						params[:status] + "|||||||||||" + 
						booking.user_email + "|" + 
						booking.user_name + "|" + 
						params[:productinfo] + "|" + 
						payment.amount.to_i.to_s + "|" + 
						payment.encoded_id.downcase + "|" + 
						PAYU_KEY
					if params[:amount] == @payment.amount && 
						params[:firstname] == booking.user_name && 
						params[:email] == booking.user_email && 
						Digest::SHA512.hexdigest(hash) == params[:hash]
						@payment.status = case params[:status]
						when 'SUCCESS' then 1
						when 'FAILURE' then 2
						when 'PENDING' then 3
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
						@payment.notes << "<b>PG_TYPE : </b>" + params[:pg_type] + "<br/>" if !params[:pg_type].blank?
						@payment.notes << "<b>Bank Ref Num : </b>" + params[:bank_ref_num] + "<br/>" if !params[:bank_ref_num].blank?
						@payment.notes << "<b>Unmapped Status : </b>" + params[:unmappedstatus] + "<br/>" if !params[:unmappedstatus].blank?
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
      redirect_to "/bookings/" + booking.encoded_id and return
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
		render layout: 'users'
	end
	
	def widget
		render json: {html: render_to_string('widget.haml')}
	end
	
	private
	
	def check_booking
		if !params[:id].blank?
			str,id = CommonHelper.decode(params[:id])
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
