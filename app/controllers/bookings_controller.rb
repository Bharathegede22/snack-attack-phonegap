class BookingsController < ApplicationController

	before_filter :check_booking, :only => [:cancel, :complete, :dopayment, :failed, :invoice, :payment, :payments, :reschedule, :show, :thanks, :feedback]
	before_filter :check_booking_user, :only => [:cancel, :invoice, :payments, :reschedule, :feedback]
	before_filter :check_search, :only => [:checkout, :checkoutab, :credits, :docreate, :docreatenotify, :license, :login, :notify, :userdetails]
	before_filter :check_search_access, :only => [:checkout, :checkoutab, :credits, :docreate, :docreatenotify, :license, :login, :userdetails]
	before_filter :check_inventory, :only => [:checkout, :checkoutab, :docreate, :dopayment, :license, :login, :payment, :userdetails]
  before_filter :check_blacklist, :only => [:docreate]

	def cancel
		@security = @booking.pricing.mode::SECURITY
		if request.post?
			@booking.valid?
			fare = @booking.do_cancellation
			flash[:notice] = "Your booking is successfully <b>cancelled</b>. <b>#{fare[:refund] - fare[:penalty] + @security}</b> will be refunded to you shortly."
		else
			@booking.status = 9
			@fare = @booking.get_fare
		end
		render json: {html: render_to_string('_cancel.haml', layout: false)}
	end
	
	def checkout
		redirect_to "/bookings/do" and return if @booking && (!user_signed_in? || (current_user && !current_user.check_details))
		generic_meta
		@header = 'booking'
	end

	def checkoutab
		redirect_to "/bookings/do" and return if @booking && (!user_signed_in? || (current_user && !current_user.check_details))
		generic_meta
		@header = 'booking'
	end
	
	def complete
		render layout: 'plain'
	end
	
	def corporate
		if !params[:clear].blank? && params[:clear].to_i == 1
  		session[:corporate_id] = nil
  	else
			session[:corporate_id] = params[:corporate_id] if !params[:corporate_id].blank?
		end
		render json: {html: render_to_string('_corporate.haml', layout: false)}
  end
	
	def credits
		if current_user.total_credits.to_i < params[:fare].to_i
			flash[:error] = 'Insufficient credits, please try again!'
		else
			session[:credits] = params[:fare].to_i
			flash[:message] = 'Credits applied, please carry on!'
		end
		#@fare = @booking.cargroup.check_fare(@booking.starts, @booking.ends)
		@fare = "Pricing#{Pricing::DEFAULT_VERSION}".check_fare_calc(@booking.starts, @booking.ends,@booking.cargroup.id,@city.id)
		render json: {html: render_to_string('_outstanding.haml', layout: false)}
	end

	def do
		if !params[:car].blank? && !params[:loc].blank? && !session[:search].blank? && !session[:search][:starts].blank? && !session[:search][:ends].blank?
			session[:book] = {:starts => session[:search][:starts], :ends => session[:search][:ends], :loc => params[:loc], :car => params[:car]}
			if params[:notify].present?
				session[:notify] = true
			end
			if user_signed_in?
				#if current_user.check_details
				#	if current_user.check_license
				#		session[:book][:steps] = 2
				#	else
				#		session[:book][:steps] = 3
				#	end
				#else
					session[:book][:steps] = 4
				#end
			else
				session[:book][:steps] = 2
			end
		elsif session[:book].blank?
			redirect_to "/" and return
		end
		if user_signed_in?
			if session[:notify].present?
				redirect_to "/bookings/notify"
			elsif current_user.check_details
				redirect_to "/bookings/checkout"
			else
				redirect_to "/bookings/userdetails"
			end
		else
			redirect_to "/bookings/login"
		end
	end
	
	def docreate
		if !session[:credits].blank? && current_user.total_credits.to_i < session[:credits].to_i
			session[:credits] = nil
			flash[:error] = 'Insufficient credits, please try again!'
			redirect_to "/bookings/checkout"
			return
		end
		
		promo = nil
		promo = Offer.get(session[:promo_code],@city) if !session[:promo_code].blank?
		
		@booking.user_id = current_user.id
		@booking.user_name = current_user.name
		@booking.user_email = current_user.email
		@booking.user_mobile = current_user.phone
		@booking.ref_initial = session[:ref_initial]
		@booking.ref_immediate = session[:ref_immediate]
		@booking.through_signup = true
		
		if promo
			@booking.promo = session[:promo_code]
			@booking.offer_id = promo[:offer].id
		end
		
		@booking.status = 11 if session[:notify].present?

		if !session[:corporate_id].blank? && current_user.support?
			@booking.corporate_id = session[:corporate_id]
			@booking.valid?
			if @booking.manage_inventory == 1
				@booking.status = 1
			else
				Inventory.block(@booking.cargroup_id, @booking.location_id, @booking.starts, @booking.ends)
				@booking.status = 6
			end
		end

		@booking.save!
		
		if promo && promo[:coupon]
			promo[:coupon].used = 1
			promo[:coupon].used_at = Time.now	
			promo[:coupon].booking_id = @booking.id
			promo[:coupon].save!
		end
		
		Credit.use_credits(@booking, session[:credits]) if !session[:credits].blank?
		
		if @booking.status == 11	
			flash[:notice] = "We will Notify you once the Vehicle is available."
			session[:notify] = nil
			redirect_to :back
		else
			session[:booking_id] = @booking.encoded_id
			session[:search] = nil
			session[:notify] = nil
			session[:book] = nil
			session[:promo_code] = nil
			session[:credits] = nil

			if !session[:corporate_id].blank? && current_user.support?
				flash[:notice] = "Corporate Booking is Successful"
				session[:corporate_id] = nil
				session[:booking_id] = nil
		  	redirect_to "/bookings/#{@booking.encoded_id}"
			elsif @booking.outstanding > 0
				redirect_to "/bookings/payment"
			else
				u = @booking.user
				if u.check_license
			  	flash[:notice] = "Thanks for the payment. Please continue."
			  	redirect_to "/bookings/#{@booking.encoded_id}"
			  	else
			  	flash[:notice] = "Thanks for the payment. Please upload your license to complete the reservation."
			  	redirect_to "/users/license"
			 	end
			end
		end
	end

	def dopayment
		session[:booking_id] = @booking.encoded_id
		redirect_to "/bookings/payment"
	end
	
	def failed
		render 'show', layout: 'users'
	end
	
	def feedback
		if request.xhr?
			# Create the feedback and stuff
			@review = Review.new(feedback_params)
			@review.booking_id = @booking.id
			@review.user_id = @booking.user_id
			@review.car_id = @booking.car_id
			@review.cargroup_id = @booking.cargroup_id
			@review.location_id = @booking.location_id
			if @review.save
				flash[:notice] = "Thank you for your feedback. Please wait..."
			else
				flash[:error] = "Please fix the following errors"
			end
			render json: { html: render_to_string('/bookings/_feedback_form.haml', :layout => false)}
		end
		generic_meta
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
		@header = 'booking'
	end
	
	def login
		redirect_to "/bookings/do" and return if user_signed_in?
		generic_meta
		@header = 'booking'
		
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
		@payment = Payment.do_create(params)
		if @payment
			@booking = @payment.booking
			session[:booking_id] = @booking.encoded_id
			if @payment.status == 1
				if @booking.confirmed_payments.length == 1
					u = @booking.user
					if u.check_license
				  	flash[:notice] = "Thanks for the payment. Please continue."
				  else
				  	flash[:notice] = "Thanks for the payment. Please upload your license to complete the reservation."
				  end
		  		redirect_to "/bookings/complete"
		  	else
		  		flash[:notice] = "Thanks for the payment. Please continue."
		  		redirect_to "/bookings/thanks"
		  	end
		  elsif @payment.status == 3
		    flash[:error] = "Your transaction is subject to manual approval by the payment gateway. We will keep you updated about the same through email."
		  	if @booking.confirmed_payments.length == 0
		  		redirect_to "/bookings/complete"
		  	else
		  		redirect_to "/bookings/thanks"
		  	end
		  else
		    flash[:error] = "Your transaction has failed. Please do a fresh transaction."
		  	redirect_to "/bookings/failed"
		  end
		else
			redirect_to '/' and return
		end
	end
  
  def promo
  	if !params[:clear].blank? && params[:clear].to_i == 1
  		session[:promo_code] = nil
  	else
			if !params[:promo].blank?
				@offer = Offer.get(params[:promo],@city)
				session[:promo_code] = params[:promo].upcase if @offer[:offer] && @offer[:error].blank?
	    end
		end
    render json: {html: render_to_string('_promo.haml', layout: false)}
  end

  def reschedule
		@confirm = !params[:confirm].blank?
		if request.post?
			if @confirm
				@booking.starts = Time.zone.parse(params[:starts]) if !params[:starts].blank?
				@booking.ends = Time.zone.parse(params[:ends]) if !params[:ends].blank?
				@booking.through_signup = true
				if @booking.valid?
					@string, @fare = @booking.do_reschedule
					if !@fare
						flash[:error] = "Sorry, but the car is no longer available"
					else
						tmp = ''
						h = @fare[:hours]
						d = h/24
						h -= d*24
						if d == 1
							tmp << "1 day, "
						elsif d > 0
							tmp << d.to_s + " days, "
						end
						if h == 1
							tmp << "1 hour"
						else
							tmp << h.to_s + " hours"
						end
						flash[:notice] = "Your booking successfully <b>" + @string.downcase.gsub('ing', 'ed') + "</b> by " + tmp.chomp(', ')
						@success = true
						@confirm = @string = @fare = nil
					end
				else
					flash[:error] = "Please fix the error!"
				end
			else
				@booking.starts = Time.zone.parse(params[:starts]) if !params[:starts].blank?
				@booking.ends = Time.zone.parse(params[:ends]) if !params[:ends].blank?
				if @booking.valid?
					@string, @fare = @booking.check_reschedule
					if !@fare && @string == 'NA'
						flash[:error] = "Sorry, but the car is no longer available"
					else
						@confirm = true
					end
				else
					flash[:error] = "Please fix the error!"
				end
			end
		end
		render json: {html: render_to_string('_reschedule.haml', layout: false)}
	end
	
	def search
		@meta_title = "Zoom - Car Hire in #{@city.name}"
		@meta_description = "Enjoy the Freedom of Four Wheels with self-drive car hire by the hour or by the day. Now in #{@city.name}!"
		@meta_keywords = "car hire, car rental, car rent, car sharing, car share, shared car, car club, rental car, car-sharing, hire car, renting a car, #{@city.name}, #{@city.name} car hire, #{@city.name} car rental, #{@city.name} car rent, #{@city.name} car sharing, #{@city.name} car share, #{@city.name} car club, #{@city.name} rental car, #{@city.name} car-sharing, #{@city.name} hire car,#{@city.name} renting a car, India, Indian, Indian car-sharing, India car-sharing, Indian car-share, India car-share, India car club, Indian car club, India car sharing, Indian car, Zoomcar, Zoom car, travel india, travel #{@city.name}, explore india, explore #{@city.name}, travel, explore, self-drive, self drive, self-drive #{@city.name}, self drive #{@city.name}"
		@canonical = "https://www.zoomcar.in/#{@city.name}/search"
		if request.post?
			@booking = Booking.new
			@booking.city_id = @city.id
			@booking.starts = Time.zone.parse(params[:starts]) if !params[:starts].blank?
			@booking.ends = Time.zone.parse(params[:ends]) if !params[:ends].blank?
			@booking.location_id = params[:loc] if !params[:loc].blank?
			@booking.cargroup_id = params[:car] if !params[:car].blank?
			@booking.valid?
			session[:search] = {:starts => params[:starts], :ends => params[:ends], :loc => params[:loc], :car => params[:car]}
			if params[:id] == 'homepage'
				render json: {html: render_to_string('_widget_homepage.haml', layout: false)}
			else
				render json: {html: render_to_string('_widget.haml', layout: false)}
			end
		else
			@booking = Booking.new
			@booking.city_id = @city.id
			@booking.starts = Time.zone.parse(session[:search][:starts]) if !session[:search].blank? && !session[:search][:starts].blank?
			@booking.ends = Time.zone.parse(session[:search][:ends]) if !session[:search].blank? && !session[:search][:ends].blank?
			@booking.location_id = session[:search][:loc] if !session[:search].blank? && !session[:search][:loc].blank?
			@booking.cargroup_id = session[:search][:car] if !session[:search].blank? && !session[:search][:car].blank?
			@inventory = Inventory.search(@city, @booking.starts, @booking.ends) if !session[:search].blank? && @booking.valid?
			@header = 'search'
		end
	end
	
	def show
		flash.keep
		render layout: 'users'
	end

	def thanks
		render layout: 'plain'
	end
	
	def timeline
		if !params[:car].blank? && !params[:location].blank? && !session[:search].blank? && !session[:search][:starts].blank? && !session[:search][:ends].blank?
			@booking = Booking.new
			@booking.starts = Time.zone.parse(session[:search][:starts])
			@booking.ends = Time.zone.parse(session[:search][:ends])
			@booking.cargroup_id = params[:car]
			@booking.location_id = params[:location]
			if params[:page].blank?
				@page = 0
			else
				@page = params[:page].to_i
			end
			@inventory = Inventory.get(@city, params[:car].to_i, params[:location].to_i, @booking.starts, @booking.ends, @page)
			if @page == 0
				render json: {html: render_to_string('timeline.haml', layout: false)}
			else
				render json: {html: render_to_string('timeline_more.haml', layout: false)}
			end
		else
			render_404
		end
	end
	
	def userdetails
		redirect_to "/bookings/do" and return if !user_signed_in? || (current_user && current_user.check_details)
		generic_meta
		@header = 'booking'
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
			str,id = CommonHelper.decode(id.downcase)
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
	
  def check_blacklist
    redirect_to "/bookings/checkout" if current_user && current_user.is_blacklisted? 
  end
  
	def check_inventory
		if @booking.valid?
			if @booking.jsi.blank? && @booking.status == 0
				cargroup = @booking.cargroup
				@available = Inventory.do_check(@city.id, @booking.cargroup_id, @booking.location_id, (@booking.starts - cargroup.wait_period.minutes), (@booking.ends + cargroup.wait_period.minutes))
				if @available == 0 && !session[:notify].present?
					flash[:error] = "Sorry, but the car is no longer available"
					redirect_to(:back) and return
				end
			end
		end
	end
	
	def check_search
		if !session[:book].blank? && !session[:book][:starts].blank? && !session[:book][:ends].blank? && !session[:book][:car].blank? && !session[:book][:loc].blank?
			@booking = Booking.new
			@booking.starts = Time.zone.parse(session[:book][:starts])
			@booking.ends = Time.zone.parse(session[:book][:ends])
			@booking.location_id = session[:book][:loc]
			@booking.cargroup_id = session[:book][:car]
			@booking.city_id = @city.id
			@booking.valid?
		end
	end
	
	def check_search_access
		redirect_to '/search' and return if !@booking || !@booking.valid?
	end
	
	def image_params
		params.require(:image).permit(:avatar)
	end
	
	def feedback_params
		params.require(:review).permit(:comment, :rating_tech, :rating_friendly, :rating_condition, :rating_location)
	end
	
end
