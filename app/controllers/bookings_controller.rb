class BookingsController < ApplicationController
	
	before_filter :check_booking, :only => [:cancel, :complete, :dopayment, :invoice, :payment, :payments, :reschedule, :show]
	before_filter :check_booking_user, :only => [:cancel, :invoice, :payments, :reschedule]
	before_filter :check_search, :only => [:docreate, :license, :login, :checkout]
	
	def cancel
		if request.post?
			fare = @booking.do_cancellation
			flash[:notice] = "Your booking is successfully <b>cancelled</b>. <b>#{fare}</b> will be refunded to you shortly."
		else
			@fare = @booking.check_cancellation
		end
		render json: {html: render_to_string('_cancel.haml', layout: false)}
	end
	
	def checkout
		generic_meta
	end
	
	def complete
		render layout: 'plain'
	end
	
	def do
		if !params[:car].blank? && !params[:loc].blank? && !session[:search].blank? && !session[:search][:starts].blank? && !session[:search][:ends].blank?
			session[:book] = {:starts => session[:search][:starts], :ends => session[:search][:ends], :loc => params[:loc], :car => params[:car]}
			if user_signed_in?
				if current_user.check_details
					if current_user.check_license
						session[:book][:steps] = 2
					else
						session[:book][:steps] = 3
					end
				else
					session[:book][:steps] = 4
				end
			else
				session[:book][:steps] = 4
			end
		elsif session[:book].blank?
			redirect_to "/" and return
		end
		if user_signed_in?
			if current_user.check_details
				if current_user.check_license
					redirect_to "/bookings/checkout"
				else
					redirect_to "/bookings/license"
				end
			else
				redirect_to "/bookings/login"
			end
		else
			redirect_to "/bookings/login"
		end
	end
	
	def docreate
		@booking.user_id = current_user.id
		@booking.user_name = current_user.name
		@booking.user_email = current_user.email
		@booking.user_mobile = current_user.phone
		@booking.through_signup = true
		@booking.save!
		session[:booking_id] = @booking.encoded_id
		session[:search] = nil
		session[:book] = nil
		redirect_to "/bookings/payment"
	end
	
	def dopayment
		session[:booking_id] = @booking.encoded_id
		redirect_to "/bookings/payment"
	end
	
	def generate
		@booking
	end
	
	def index
		render layout: 'users'
	end
	
	def invoice
		render layout: 'plain'
	end
	
	def license
		redirect_to "/bookings/do" and return if user_signed_in? && current_user.check_license
		if request.post?
			if !params[:image].blank?
				image = Image.new(image_params)
				image.imageable_id = current_user.id
				image.imageable_type = 'License'
				if image.save
					if !params[:license].blank?
						current_user.license = params[:license]
						#current.license_check = true
						current_user.save(validate: false)
					end
					flash[:notice] = 'Thanks for uploading your license image.'
					redirect_to "/bookings/do" and return
				else
					if image.errors[:avatar_content_type].length > 0
						flash[:error] = 'Please attach a valid license image. Only allow formats are jpg, jpeg, gif and png.'
					else
						flash[:error] = 'Please attach a valid license image. Maximum allowedd file size is 2 MB.'
					end
					redirect_to "/bookings/do" and return
				end
			else
				flash[:error] = 'Please attach a license image'
			end
		end
		generic_meta
	end
	
	def login
		redirect_to "/bookings/do" and return if user_signed_in? && current_user.check_details
		generic_meta
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
						params[:firstname] == @booking.user_name.strip && 
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
	
	def reschedule
		@confirm = !params[:confirm].blank?
		if request.post?
			if @confirm
				@booking.ends = DateTime.parse(params[:ends] + " +05:30") if !params[:ends].blank?
				@booking.through_signup = true
				if @booking.valid?
					@string, @fare = @booking.do_reschedule
					if !@fare
						flash[:error] = "Sorry, but the car is no longer available"
					else
						tmp = ''
						if @fare[:days] == 1
							tmp << "1 day, "
						elsif @fare[:days] > 0
							tmp << @fare[:days].to_s + " days, "
						end
						if @fare[:hours] == 1
							tmp << "1 hour"
						elsif @fare[:hours] > 0
							tmp << @fare[:hours].to_s + " hours"
						end
						flash[:notice] = "Your booking <b>" + @string.downcase.gsub('ing', 'ed') + "</b> by " + tmp.chomp(', ') + " successfully"
						@success = true
						@confirm = @string = @fare = nil
					end
				else
					flash[:error] = "Please fix the error!"
				end
			else
				@booking.ends = DateTime.parse(params[:ends] + " +05:30") if !params[:ends].blank?
				if @booking.valid?
					@string, @fare = @booking.check_reschedule
					flash[:error] = "Sorry, but the car is no longer available" if !@fare && @string == 'NA'
					@confirm = true
				else
					flash[:error] = "Please fix the error!"
				end
			end
		end
		render json: {html: render_to_string('_reschedule.haml', layout: false)}
	end
	
	def search
		@meta_title = "Zoom - Car Hire in Bangalore"
		@meta_description = "Enjoy the Freedom of Four Wheels with self-drive car hire by the hour or by the day. Now in Bangalore!"
		@meta_keywords = "car hire, car rental, car rent, car sharing, car share, shared car, car club, rental car, car-sharing, hire car, renting a car, bangalore, bangalore car hire, bangalore car rental, bangalore car rent, bangalore car sharing, bangalore car share, bangalore car club, bangalore rental car, bangalore car-sharing, bangalore hire car, bagalore renting a car, India, Indian, Indian car-sharing, India car-sharing, Indian car-share, India car-share, India car club, Indian car club, India car sharing, Indian car, Zoomcar, Zoom car, travel india, travel bangalore, explore india, explore bangalore, travel, explore, self-drive, self drive, self-drive bangalore, self drive bangalore"
		@canonical = "https://www.zoomcar.in/search"
		if request.post?
			@booking = Booking.new
			@booking.starts = DateTime.parse(params[:starts] + " +05:30") if !params[:starts].blank?
			@booking.ends = DateTime.parse(params[:ends] + " +05:30") if !params[:ends].blank?
			@booking.location_id = params[:loc] if !params[:loc].blank?
			@booking.cargroup_id = params[:car] if !params[:car].blank?
			@booking.through_search = true
			@booking.valid?
			session[:search] = {:starts => params[:starts], :ends => params[:ends], :loc => params[:loc], :car => params[:car]}
			if params[:id] == 'homepage'
				render json: {html: render_to_string('_widget_homepage.haml', layout: false)}
			else
				render json: {html: render_to_string('_widget.haml', layout: false)}
			end
		else
			@booking = Booking.new
			@booking.starts = DateTime.parse(session[:search][:starts] + " +05:30") if !session[:search].blank? && !session[:search][:starts].blank?
			@booking.ends = DateTime.parse(session[:search][:ends] + " +05:30") if !session[:search].blank? && !session[:search][:ends].blank?
			@booking.location_id = session[:search][:loc] if !session[:search].blank? && !session[:search][:loc].blank?
			@booking.cargroup_id = session[:search][:car] if !session[:search].blank? && !session[:search][:car].blank?
			@booking.through_search = true
			if @booking.valid?
				if !@booking.cargroup_id.blank? && !@booking.location_id.blank?
					@inventory = {}
					@inventory[@booking.cargroup_id.to_s] = {@booking.location_id.to_s => Inventory.check(@booking.starts, @booking.ends, @booking.cargroup_id, @booking.location_id)}
				else
					@inventory = Inventory.check(@booking.starts, @booking.ends, @booking.cargroup_id, @booking.location_id)
				end
			end
			@header = 'search'
		end
	end
	
	def show
		flash.keep
		render layout: 'users'
	end
	
	def widget
		render json: {html: render_to_string('_widget.haml', layout: false)}
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
	
	def check_booking_user
		if user_signed_in?
			if current_user.support? || @booking.user_id == current_user.id
			else
				flash[:error] = "Booking doesn't belongs to you"
				if request.xhr?
					render json: {html: render_to_string('/devise/sessions/new.haml', :layout => false)} and return
				else
					redirect_to "/users/sign_in" and return
				end
			end
		else
			if request.xhr?
				render json: {html: render_to_string('/devise/sessions/new.haml', :layout => false)} and return
			else
				redirect_to "/users/sign_in" and return
			end
		end
	end
	
	def check_search
		if !session[:book].blank? && !session[:book][:starts].blank? && !session[:book][:ends].blank? && !session[:book][:car].blank? && !session[:book][:loc].blank?
			@booking = Booking.new
			@booking.starts = DateTime.parse(session[:book][:starts] + " +05:30")
			@booking.ends = DateTime.parse(session[:book][:ends] + " +05:30")
			@booking.location_id = session[:book][:loc]
			@booking.cargroup_id = session[:book][:car]
			@available = Inventory.check(@booking.starts, @booking.ends, @booking.cargroup_id, @booking.location_id)
			flash[:error] = "Sorry, but the car is no longer available" if @available == 0
		else
			redirect_to "/" and return
		end
	end
	
	def image_params
		params.require(:image).permit(:avatar)
	end
	
end
