class BookingsController < ApplicationController
	
	before_filter :check_booking, :only => [:cancel, :complete, :dopayment, :failed, :invoice, :payment, :payments, :reschedule, :show, :thanks, :feedback]
	before_filter :check_booking_user, :only => [:cancel, :invoice, :payments, :reschedule, :feedback]
	before_filter :check_search, :only => [:checkout, :docreate, :license, :login, :userdetails]
	before_filter :check_inventory, :only => [:checkout, :docreate, :dopayment, :license, :login, :payment, :userdetails]
	
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
		redirect_to "/bookings/do" and return if !user_signed_in? || (current_user && !current_user.check_details)
		generic_meta
		@header = 'booking'
	end
	
	def complete
		render layout: 'plain'
	end
	
	def credits
		if params[:fare].to_i >= current_user.total_credits.to_i
			session[:used_credits] = current_user.total_credits.to_i
		else
			session[:used_credits] = params[:fare].to_i

		end
		flash[:notice] = "Remaining Credits: #{current_user.total_credits.to_i - session[:used_credits]}" 
		session[:cr_netamount] = params[:fare].to_i - session[:used_credits].to_i
		render json: {html: render_to_string('_credits.haml', layout: false)}
	end


	def do
		if !params[:car].blank? && !params[:loc].blank? && !session[:search].blank? && !session[:search][:starts].blank? && !session[:search][:ends].blank?
			session[:book] = {:starts => session[:search][:starts], :ends => session[:search][:ends], :loc => params[:loc], :car => params[:car]}
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
			if current_user.check_details
				redirect_to "/bookings/checkout"
			else
				redirect_to "/bookings/userdetails"
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
		@booking.ref_initial = session[:ref_initial]
		@booking.ref_immediate = session[:ref_immediate]
		@booking.through_signup = true
		@booking.promo = session[:promo_code] if !session[:promo_code].blank?
		#@booking.credit = Credit.new(status: 0,user_id: current_user.id, amount: session[:used_credits])   #to do recalculate session hijacking
		@booking.save!

		payment = Payment.new
		payment.booking_id = @booking.id
		payment.status = 1
		payment.through = 'credits'
		payment.amount = session[:used_credits]
		payment.save!

		credit = Credit.new
		credit.user_id = current_user.id
		credit.creditable_type = 'booking'
		credit.amount = session[:used_credits]
		credit.action = 'debit'
		credit.source_name = 'booking'
		credit.status = 1
		credit.creditable_id = @booking.id
		credit.save!

		current_user.update_credits

		session[:used_credits] = nil

		session[:booking_id] = @booking.encoded_id
		session[:search] = nil
		session[:book] = nil
		session[:promo_code] = nil
		redirect_to "/bookings/payment"
	end
	
	def dopayment
		session[:booking_id] = @booking.encoded_id
		redirect_to "/bookings/payment"
	end
	
	def failed
		render 'thanks', layout: 'plain'
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
				if CommonHelper::DISCOUNT_CODES.include?(params[:promo].upcase) || Offer.find_by(promo_code: params[:promo].upcase, status: Offer::ACTIVE).present?
					session[:promo_code] = params[:promo]
				else
					flash[:error] = "No active offer is found for <b>#{params[:promo]}</b>."
		  	end
		  end
		end
    render json: {html: render_to_string('_promo.haml', layout: false)}
  end
	
	def reschedule
		@confirm = !params[:confirm].blank?
		if request.post?
			if @confirm
				@booking.ends = Time.zone.parse(params[:ends]) if !params[:ends].blank?
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
						flash[:notice] = "Your booking successfully <b>" + @string.downcase.gsub('ing', 'ed') + "</b> by " + tmp.chomp(', ')
						@success = true
						@confirm = @string = @fare = nil
					end
				else
					flash[:error] = "Please fix the error!"
				end
			else
				@booking.ends = Time.zone.parse(params[:ends]) if !params[:ends].blank?
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
			@booking.starts = Time.zone.parse(params[:starts]) if !params[:starts].blank?
			@booking.ends = Time.zone.parse(params[:ends]) if !params[:ends].blank?
			@booking.location_id = params[:loc] if !params[:loc].blank?
			@booking.cargroup_id = params[:car] if !params[:car].blank?
			@booking.through_search = true
			@booking.valid?
			session[:search] = {:starts => params[:starts], :ends => params[:ends], :loc => params[:loc], :car => params[:car]}
			if params[:id] == 'homepage_ab'
				render json: {html: render_to_string('_widget_homepage_ab.haml', layout: false)}
			elsif params[:id] == 'homepage'
				render json: {html: render_to_string('_widget_homepage.haml', layout: false)}
			else
				render json: {html: render_to_string('_widget.haml', layout: false)}
			end
		else
			@booking = Booking.new
			@booking.starts = Time.zone.parse(session[:search][:starts]) if !session[:search].blank? && !session[:search][:starts].blank?
			@booking.ends = Time.zone.parse(session[:search][:ends]) if !session[:search].blank? && !session[:search][:ends].blank?
			@booking.location_id = session[:search][:loc] if !session[:search].blank? && !session[:search][:loc].blank?
			@booking.cargroup_id = session[:search][:car] if !session[:search].blank? && !session[:search][:car].blank?
			@booking.through_search = true
			@inventory = Inventory.check(@booking.starts, @booking.ends, nil, nil) if !session[:search].blank? && @booking.valid?
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
			@inventory = Inventory.get(params[:car].to_i, params[:location].to_i, @booking.starts, @booking.ends, @page)
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
	
	def check_inventory
		if @booking
			if @booking.jsi.blank? && @booking.status == 0
				@available = Inventory.check(@booking.starts, @booking.ends, @booking.cargroup_id, @booking.location_id)
				if @available == 0
					flash[:error] = "Sorry, but the car is no longer available"
					redirect_to(:back) and return
				end
			end
		else
			redirect_to "/" and return
		end
	end
	
	def check_search
		if !session[:book].blank? && !session[:book][:starts].blank? && !session[:book][:ends].blank? && !session[:book][:car].blank? && !session[:book][:loc].blank?
			@booking = Booking.new
			@booking.starts = Time.zone.parse(session[:book][:starts])
			@booking.ends = Time.zone.parse(session[:book][:ends])
			@booking.location_id = session[:book][:loc]
			@booking.cargroup_id = session[:book][:car]
		else
			redirect_to "/" and return
		end
	end
	
	def image_params
		params.require(:image).permit(:avatar)
	end
	
	def feedback_params
		params.require(:review).permit(:comment, :rating_tech, :rating_friendly, :rating_condition, :rating_location)
	end
	

	
end
