class BookingsController < ApplicationController
  
  include ApplicationHelper
  include BookingsHelper

  before_filter :authenticate_user!, :only => [:checkout, :promo, :docreate]
	before_filter :copy_params, :only => [:docreate, :seamless_docreate]
	before_filter :check_booking, :only => [:holddeposit, :cancel, :complete, :dodeposit, :seamless_dodeposit, :dopayment, :seamless_dopayment, :seamless_payment_options, :failed, :invoice, :payment, :payments, :reschedule, :show, :thanks, :feedback]
	before_filter :check_booking_user, :only => [:holddeposit, :dodeposit, :seamless_dodeposit, :cancel, :invoice, :payments, :reschedule, :feedback]
	before_filter :check_search, :only => [:checkout, :checkoutab, :credits, :docreate, :seamless_docreate, :docreatenotify, :license, :login, :notify, :userdetails, :promo]
	before_filter :check_search_access, :only => [:docreate, :seamless_docreate, :docreatenotify, :license, :login, :userdetails]
	before_filter :check_inventory, :only => [:checkout, :checkoutab, :docreate, :seamless_docreate, :dopayment, :seamless_dopayment, :license, :login, :payment, :userdetails]
	before_filter :check_blacklist, :only => [:docreate, :seamless_docreate]
	before_filter :clear_credit_and_offers, :only => [:checkout]

	def cancel
		@security = (@booking.hold) ? 0 : (@booking.pricing.mode::SECURITY - @booking.security_amount_remaining)
		if request.post?
			@booking.valid?
			@fare = @booking.do_cancellation
			flash[:notice] = "Your booking is successfully <b>cancelled</b>. <b>#{@fare[:refund] - @fare[:penalty] + @security}</b> will be refunded to you shortly."
		else
			@booking.status = 9
			@fare = @booking.get_fare
		end
		render json: {html: render_to_string('_cancel.haml', layout: false)}
	end
	
	def checkout
		@booking.user = current_user
		@wallet_available = @booking.security_amount - @booking.security_amount_remaining
		redirect_to do_bookings_path(@city.link_name.downcase) and return if @booking && (!user_signed_in? || (current_user && !current_user.check_details))
		check_deal
		generic_meta
		@header = 'booking'
		render :checkouta
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

	# creates order for payment on juspay
	#
	# Author:: Aniket
	# Date:: 05/12/2014
	#  
  def createorder
  	bstr, bid = CommonHelper.decode(params[:booking])
  	pstr, pid = CommonHelper.decode(params[:payment])
  	if bstr == 'booking' && pstr == 'payment'
	  	@booking = Booking.find(bid)
	  	@payment = Payment.find(pid)
	  else
	  	return
	  end
		# Creating order on juspay
		data = { amount: @payment.amount.to_i, order_id: @payment.encoded_id, customer_id: @booking.user.encoded_id, customer_email: @booking.user.email, customer_phone: @booking.user.mobile, return_url: "http://#{HOSTNAME}/bookings/pgresponse" }
		response = Juspay.create_order(data)

		if response['status'].downcase == 'created' || response['status'].downcase == 'new'
			render :json => {status: 'success'}
		elsif response['status'].downcase == 'error'
			flash[:error] = "Something went wrong. Please try again."
			render :json => {:response => 'pg error'}
		end
  end

  # Applies credits to user booking
  #
  # Author:: Rohit
  # Date:: 22/10/2014
  # Expects ::
  #   <b>params[:apply_credits]</b>  Integer  1/0
  # 	<b>params[:remove_credits]</b> Integer  1/0
  #
	def credits
    @booking.user = current_user
    if params[:apply_credits].to_i > 0
      result = @booking.apply_credits(current_user.total_credits)
      if result[:error].nil?
        session[:credits] = result[:credits].to_i
      else
        flash[:error] = result[:error]
      end
    elsif params[:remove_credits].to_i > 0
      session[:credits] = nil
    end
		render json: {html: render_to_string('_credits.haml', :locals => {:fare => @booking.get_fare}, layout: false)}
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
		# session[:deal] = nil
		if user_signed_in?
			if session[:notify].present?
				redirect_to "/bookings/notify"
			elsif current_user.check_details
				if session[:deal].present?
					redirect_to bookings_do_flash_booking_path(deal: session[:deal])
				else
					redirect_to checkout_bookings_path(@city.link_name.downcase)
				end
			else
				redirect_to userdetails_bookings_path(@city.link_name.downcase)
			end
		else
			redirect_to login_bookings_path(@city.link_name.downcase)
		end
	end

	def do_flash_booking
		if params[:deal].present? || session[:deal].present?#!params[:car].blank? && !params[:loc].blank? && !params[:starts].blank? && !params[:ends].blank? && !params[:flash_discount].blank?
			str, id = params[:deal].present? ? CommonHelper.decode(params['deal']) : CommonHelper.decode(session[:deal])
			if str == 'deal'
				deal = Deal.find_by(id: id)
				if deal && deal.offer_start <= DateTime.now && deal.offer_end >= DateTime.now && deal.booking_id.blank?
					session[:book] = {:starts => deal.starts.to_s, :ends => deal.ends.to_s, :loc => deal.location_id, :car => deal.cargroup_id}
				elsif deal.booking_id.present?
					flash.keep[:notice] = 'Deal has already been taken. Please check back again after some time.'
					redirect_to '/deals' and return
				end
				id = CommonHelper.encode('deal', deal.id)
					session[:deal] = id
				if user_signed_in?
					if current_user.check_details
						redirect_to checkout_bookings_path(@city.link_name.downcase, deal: id)
					else
						redirect_to userdetails_bookings_path(@city.link_name.downcase, deal: id)
					end
				else
					redirect_to login_bookings_path(@city.link_name.downcase, deal: id)
				end
			end
		else
			redirect_to '/deals' and return
		end
	end
	
	def docreate
		@booking.user_details(current_user)
		@booking.ref_initial = session[:ref_initial]
		@booking.ref_immediate = session[:ref_immediate]
		@booking.through_signup = true
		@booking.status = 11 if session[:notify].present?
		
		# Defer Deposit
		@booking.defer_deposit = true if @booking.defer_allowed? && session[:book][:deposit] == 0

		# Check Offer / Credit
		if CommonHelper.offers_credits_live?
			apply_credits_and_coupons
		else
			promo = nil
			promo = Offer.get(session[:promo_code],@city) if !session[:promo_code].blank?
			if !session[:promo_booking].blank?
				@booking = Booking.find(session[:promo_booking])
				session[:promo_booking] = nil
				@booking.status = 0
			end
			if promo
				@booking.promo = session[:promo_code]
				@booking.offer_id = promo[:offer].id
			end
		end

		if session[:deal].present? && @booking.promo.nil?
			@booking.promo = find_deal_and_create_charge(session[:deal])
			redirect_to '/deals' and return if @booking.promo == "taken"
			@booking.promo = nil if @booking.promo == "nodeal"
		end

		# Corporate Booking
		if !session[:corporate_id].blank? && current_user.support?
			@booking.corporate_id = session[:corporate_id]
			if @booking.manage_inventory == 1
				@booking.status = 1
			else
				Inventory.block(@booking.cargroup_id, @booking.location_id, @booking.starts, @booking.ends)
				@booking.status = 6
			end
		end
		
		@booking.save!

		# check for flash deal
		deal = @booking.promo
		if deal.present? && deal.include?('SQUIRREL')
			str, deal = CommonHelper.decode(deal[8, deal.length])
			if str == 'deal' && deal == @deal.id
				@booking.flash_discount(@deal)
			end
		end

		# Create Credits Payments and Offers Charges
		if CommonHelper.offers_credits_live?
			create_promo_credit_payments 
		else
			# Expiring Coupon Code
			if promo && promo[:coupon]
				promo[:coupon].used = 1
				promo[:coupon].used_at = Time.now	
				promo[:coupon].booking_id = @booking.id
				promo[:coupon].save!
			end
		end
		
		if @booking.status == 11	
			flash[:notice] = "We will Notify you once the Vehicle is available."
			session[:notify] = nil
			redirect_to :back
		else
			session[:booking_id] = @booking.encoded_id
			session[:search] 			= nil
			session[:notify] 			= nil
			session[:book] 				= nil
			session[:promo_code] 	= nil
			session[:promo_valid] = false
			session[:promo_message] = ""
			session[:credits] 		= nil
      session[:deal] = nil if !(deal.present? && @booking.promo.include?('SQUIRREL'))
			if !session[:corporate_id].blank? && current_user.support?
				flash[:notice] = "Corporate Booking is Successful"
				session[:corporate_id] = nil
				session[:booking_id] = nil
		  	redirect_to "/bookings/#{@booking.encoded_id}"
			elsif @booking.outstanding_with_security > 0
				redirect_to payment_bookings_path(@city.link_name.downcase, id: @booking.encoded_id)
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

	# Apply Credits and Offers
	def apply_credits_and_coupons
		# Check Offer
		promo_params = updated_params(params)
		if session[:promo_code].present?
  		promo_params[:promo] = session[:promo_code]
  		promo = make_promo_api_call(promo_params)
  		update_sessions(promo)
			if session[:promo_valid]
				@booking.promo = session[:promo_code]
				@booking.offer_id = session[:promo_offer_id]
			end
		end

		# Apply credits to booking
		apply_credits if session[:credits].present?
	end

	# Create Credits Payments and Offers Charges
	def create_promo_credit_payments
		# Expiring Coupon Code
		if session[:promo_valid] && session[:promo_coupon_id].present?
			Offer.update_coupon(session[:promo_coupon_id], @booking.id)
		end
		#create a charge if booking has been created and promocode exist
		if @booking.id && session[:promo_valid]
			params[:booking_id] = @booking.id
			params[:amount] = session[:promo_discount]
			#create discount charge
			url = "#{ADMIN_HOSTNAME}/mobile/v3/bookings/create_discount_charge"
    	res = admin_api_get_call(url, params)
		end
		# Using crredits
		Credit.use_credits(@booking, session[:credits]) if session[:credits].present?
	end
	
	def dodeposit
		defer_deposit = params[:checkoutDeposit] != "1"
		@booking.update_column(:defer_deposit, defer_deposit)
		# @booking.update_column(:defer_deposit, false) if params[:checkoutDeposit]=="1"
		if !@booking.defer_allowed?
			@booking.add_security_deposit_charge
			#amount = @booking.user.wallet_available_on_time(@booking.starts - CommonHelper::WALLET_FREEZE_START.hours,@booking) 
			##@Abhas it'll calculate past amount as already within 24 hours
			@booking.make_payment_from_wallet		
		end
		redirect_to "/bookings/#{@booking.encoded_id}/dopayment"
	end
  
	def dopayment
		session[:booking_id] = @booking.encoded_id
		redirect_to payment_bookings_path(@city.link_name.downcase, id: @booking.encoded_id)
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
	
	def holddeposit
		@booking.update_attribute(:hold, true)
    if @booking.hold_security?
    activities_params = {user_id: @booking.user_id, booking_id: @booking.id, activity: Activity::ACTIVITIES[:on_hold]}
    Activity.create_activity(activities_params)
    end
    respond_to do |format|
			format.json {render :json =>{:error=>'', :messag=> 'Hold Successful'}}
			format.html {redirect_to '/bookings'}
		end
	end

	def index
		render layout: 'users'
	end
	
	def invoice
		render layout: 'plain'
	end
	
	def license
		redirect_to do_bookings_path(@city.link_name.downcase) and return if user_signed_in? && current_user.check_license
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
					redirect_to do_bookings_path(@city.link_name.downcase) and return
				else
					if image.errors[:avatar_content_type].length > 0
						flash[:error] = 'Please attach a valid license image. Only allow formats are jpg, jpeg, gif and png.'
					else
						flash[:error] = 'Please attach a valid license image. Maximum allowedd file size is 2 MB.'
					end
					redirect_to do_bookings_path(@city.link_name.downcase) and return
				end
			else
				flash[:error] = 'Please attach a license image'
			end
		end
		generic_meta
		@header = 'booking'
	end
	
	def login
		redirect_to do_bookings_path(@city.link_name.downcase) and return if user_signed_in?
		check_deal
		generic_meta
		@header = 'booking'
		
	end
	
	def payment
		@payment = @booking.check_payment
		if @payment
			@newflow = abtest? ? true : false # abtest
			render :layout => 'plain'
		else
			flash[:notice] = "Booking is already paid for full, no need for a new transaction."
      redirect_to "/bookings/" + @booking.encoded_id and return
    end
	end
	
	# renders payment options UI
	#
	# Author:: Aniket
	# Date:: 05/12/2014
	#  
	def payment_options
		redirect_to '/' and return if params[:pid].blank? || params[:bid].blank?
		bstr, bid = CommonHelper.decode(params[:bid])
		pstr, pid = CommonHelper.decode(params[:pid])
		if bstr == 'booking' && pstr == 'payment'
			@booking = Booking.find(bid)
			@payment = Payment.find(pid)
			hash = PAYU_KEY + "|" + @payment.encoded_id + "|" + @payment.amount.to_i.to_s + "|" + @booking.cargroup.display_name + "|" + @booking.user.name.strip + "|" + @booking.user.email + "|||||||||||" + PAYU_SALT
			@hash = Digest::SHA512.hexdigest(hash)
			render '/bookings/pg/new_payment', layout: 'plain'
		else
			redirect_to '/' and return
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
					#@booking.add_security_deposit_charge if @booking.security_amount_deferred?
					if u.check_license
				  	flash[:notice] = "Thanks for the payment. Please continue."
				  else
				  	flash[:notice] = "Thanks for the payment. Please upload your license to complete the reservation."
				  end
		  		redirect_to "/#{@city.link_name.downcase}/bookings/complete" #complete_bookings_path(@city.link_name.downcase)
		  	else
		  		flash[:notice] = "Thanks for the payment. Please continue."
		  		redirect_to thanks_bookings_path
		  	end
		  elsif @payment.status == 3
		    flash[:error] = "Your transaction is subject to manual approval by the payment gateway. We will keep you updated about the same through email."
		  	if @booking.confirmed_payments.length == 0
		  		redirect_to "/#{@city.link_name.downcase}/bookings/complete" #complete_bookings_path(@city.link_name.downcase)
		  	else
		  		redirect_to thanks_bookings_path
		  	end
		  else
		    flash[:error] = "Your transaction has failed. Please do a fresh transaction."
		  	redirect_to failed_bookings_path(@city.link_name.downcase)
		  end
		else
			redirect_to '/' and return
		end
	end

	def pgresponse
		if params['order_id'].present?		#juspay
			@payment = Payment.juspay_create(params)
		elsif params['mihpayid'].present?	#payu
			@payment = Payment.do_create(params)
		end
		if @payment
			@booking = @payment.booking
			session[:booking_id] = @booking.encoded_id
			if @payment.status == 1
				if @booking.confirmed_payments.length == 1
					u = @booking.user
					#@booking.add_security_deposit_charge if @booking.security_amount_deferred?
					if session[:book].present?
						session[:search] 			= nil
						session[:notify] 			= nil
						session[:book] 				= nil
						session[:promo_code] 	= nil
						session[:credits] 		= nil
					end
					if u.check_license
				  	flash[:notice] = "Thanks for the payment. Please continue."
				  else
				  	flash[:notice] = "Thanks for the payment. Please upload your license to complete the reservation."
				  end
		  		redirect_to "/#{@city.link_name.downcase}/bookings/complete"
		  	else
		  		flash[:notice] = "Thanks for the payment. Please continue."
		  		redirect_to thanks_bookings_path
		  		# redirect_to "/bookings/thanks"
		  	end
		  elsif @payment.status == 3
		    flash[:error] = "Your transaction is subject to manual approval by the payment gateway. We will keep you updated about the same through email."
		  	if @booking.confirmed_payments.length == 0
		  		redirect_to "/#{@city.link_name.downcase}/bookings/complete"
		  	else
		  		redirect_to "/bookings/thanks"
		  	end
		  else
		    flash[:error] = "Your transaction has failed. Please do a fresh transaction."
		  	redirect_to "/bookings/failed"
		  	# redirect_to failed_bookings_path(@city.link_name.downcase)
		  end
		else
			redirect_to '/' and return
		end
	end

  def promo
  	if CommonHelper.offers_credits_live?
	  	if params[:clear].to_i == 1
	  		session[:promo_code] = nil
	  		session[:promo_message] = nil
	  		session[:promo_valid] = false
	  	end

			promo_params = updated_params(params)
			promo = make_promo_api_call(promo_params)
			update_sessions(promo) unless promo.nil?

	    render json: { 
	    	promo: render_to_string('_promo.haml', layout: false),
	  		credit: render_to_string('_credits.haml', :locals => {:fare => @booking.get_fare}, layout: false)
	  	}
	  else
	  	b = check_booking_obj
	  	if !params[:clear].blank? && params[:clear].to_i == 1
	  		session[:promo_code] = nil
				b.update_column(:promo, nil) if b
	  	else
				if !params[:promo].blank?
					@offer = Offer.get(params[:promo],@city)
					session[:promo_code] = params[:promo].upcase if @offer[:offer] && @offer[:error].blank?
					promo = nil
					promo = Offer.get(session[:promo_code],@city) if !session[:promo_code].blank?
	      	b.update_column(:promo, session[:promo_code]) if b
		    end
			end
	    render json: {html: render_to_string('_promo.haml', layout: false)}
	  end
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
						@booking.update_column(:defer_deposit, false) if !params[:deposit].blank? && params[:deposit].to_i == 1
						if CommonHelper.offers_credits_live?(@booking.created_at) && @booking.offer_id.present? && @booking.promo.present?
							reschedule_params = update_reschedule_params(params, @booking)
							response = make_promo_api_call(reschedule_params)
							promo = response["promo"]
							offer_discount = @booking.total_discount
							create_reschedule_offer_charge(@booking.id, promo, offer_discount)
						end
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
						if CommonHelper.offers_credits_live?(@booking.created_at) && @booking.offer_id.present? && @booking.promo.present?
							reschedule_params = update_reschedule_params(params, @booking)
							response = make_promo_api_call(reschedule_params)
							update_sessions(response)
						end
					end
				else
					flash[:error] = "Please fix the error!"
				end
			end
		end
		@wallet_available = @booking.security_amount - @booking.security_amount_remaining
		render json: {html: render_to_string('_reschedule.haml', layout: false)}
	end

	def resume_booking
		if !session[:book].blank?
			redirect_to '/bookings/do'
		elsif !session[:search].blank?
			redirect_to '/search'
		elsif !session[:booking_id].blank? && session[:book].blank? && session[:search].blank?
			redirect_to "/bookings/" + session[:booking_id]
		elsif session[:book].blank? && session[:search].blank?
			redirect_to '/'
		end
	end
	
	def seamless_docreate
		# check for existing booking with the same details if user reloads checkout page after going for payment
		@booking = check_booking_obj
		check_search if @booking.blank?
		@booking.user_details(current_user)
		@booking.ref_initial = session[:ref_initial]
		@booking.ref_immediate = session[:ref_immediate]
		@booking.through_signup = true
		@booking.status = 11 if session[:notify].present?
		
		# Defer Deposit
		@booking.defer_deposit = true if @booking.defer_allowed? && session[:book][:deposit] == 0
		
		apply_credits_and_coupons()
		
		# Corporate Booking
		if !session[:corporate_id].blank? && current_user.support?
			@booking.corporate_id = session[:corporate_id]
			if @booking.manage_inventory == 1
				@booking.status = 1
			else
				Inventory.block(@booking.cargroup_id, @booking.location_id, @booking.starts, @booking.ends)
				@booking.status = 6
			end
		end
		
		@booking.save!

		# Create Credits Payments and Offers Charges
		create_promo_credit_payments
		
		@booking.reload

		if @booking.status == 11	
			flash[:notice] = "We will Notify you once the Vehicle is available."
			session[:notify] = nil
	  	render :json => {:response => 'unavailable'}
		else
			session[:book][:id] = @booking.encoded_id
			session[:booking_id] = @booking.encoded_id
			# session[:search] 			= nil
			# session[:notify] 			= nil
			# session[:book] 				= nil
			# session[:promo_code] 	= nil
			# session[:credits] 		= nil
			if !session[:corporate_id].blank? && current_user.support?
				flash[:notice] = "Corporate Booking is Successful"
				session[:corporate_id] = nil
				session[:booking_id] = nil
				session[:search] = nil
				session[:notify] = nil
				session[:promo_code] 	= nil
				session[:book] = nil
		  	render :json => {:response => 'corporate', :id => @booking.encoded_id}
			elsif @booking.outstanding > 0
				@payment = @booking.check_payment
				if @payment
					# Creating order on juspay
					data = { amount: @payment.amount.to_i, order_id: @payment.encoded_id, customer_id: @booking.user.encoded_id, customer_email: @booking.user.email, customer_mobile: @booking.user.phone, return_url: "http://#{HOSTNAME}/bookings/pgresponse", udf1: "web", udf2: "desktop" }
					response = Juspay.create_order(data)

					if response['status'].downcase == 'created' || response['status'].downcase == 'new'
						hash = PAYU_KEY + "|" + @payment.encoded_id + "|" + @payment.amount.to_i.to_s + "|" + @booking.cargroup.display_name + "|" + @booking.user.name.strip + "|" + @booking.user.email + "|||||||||||" + PAYU_SALT
						render :json => {:response => response['status'].downcase, :amt => @payment.amount.to_i, :order_id => @payment.encoded_id, :name => @booking.user.name, :email => @booking.user.email, :phone => @booking.user.phone, :desc => @booking.cargroup.display_name, :product_id => @booking.cargroup.brand_id, :cust_id => @booking.user.encoded_id, :hash => Digest::SHA512.hexdigest(hash)}
					elsif response['status'].downcase == 'error'
						
				  	flash[:error] = "Something went wrong. Please try again."
						render :json => {:response => 'pg error'}
					end

				else
					flash[:notice] = "Booking is already paid for full, no need for a new transaction."
			  	render :json => {:response => 'paid', :id => @booking.encoded_id}
		    end
			else
				u = @booking.user
				if u.check_license	
			  	flash[:notice] = "Thanks for the payment. Please continue."
			  	render :json => {:response => 'paid license checked', :id => @booking.encoded_id}
			  	else
			  	flash[:notice] = "Thanks for the payment. Please upload your license to complete the reservation."
			  	render :json => {:response => 'paid no license', :id => @booking.encoded_id}
			 	end
			end
		end
	end

	def seamless_dodeposit
		if params[:checkoutDeposit] == "1"
			@booking.update_column(:defer_deposit, false)
		elsif params[:checkoutDeposit] == "0"
			@booking.update_column(:defer_deposit, true)
		end
		if !@booking.defer_allowed?
			@booking.add_security_deposit_charge
			@booking.make_payment_from_wallet
		end
		session[:booking_id] = @booking.encoded_id
		resp = Booking.create_payment(@booking)
		render :json=> resp
	end

	def seamless_dopayment
		session[:booking_id] = @booking.encoded_id
		resp = Booking.create_payment(@booking)
		render :json=> resp
	end

	def seamless_payment_options
		render :json => {html: render_to_string('/bookings/pg/_payment_options.haml', layout: false)}
	end

	def seamless_update_payment
		if !params[:deposit].nil? && params[:id].present?
			resp = Payment.update(params[:id], params[:deposit])
			render :json => resp
		else
			render :json => {:status=> 'error', :msg => "param deposit or id missing"}
		end
	end


  def search
    @meta_title = "Zoom - Car Rental in #{@city.name}"
    @meta_description = "Enjoy the Freedom of Four Wheels with self-drive car rental by the hour or by the day. Now in #{@city.name}!"
    @meta_keywords = "car hire, car rental, car rent, car sharing, car share, shared car, car club, rental car, car-sharing, hire car, renting a car, #{@city.name}, #{@city.name} car hire, #{@city.name} car rental, #{@city.name} car rent, #{@city.name} car sharing, #{@city.name} car share, #{@city.name} car club, #{@city.name} rental car, #{@city.name} car-sharing, #{@city.name} hire car,#{@city.name} renting a car, India, Indian, Indian car-sharing, India car-sharing, Indian car-share, India car-share, India car club, Indian car club, India car sharing, Indian car, Zoomcar, Zoom car, travel india, travel #{@city.name}, explore india, explore #{@city.name}, travel, explore, self-drive, self drive, self-drive #{@city.name}, self drive #{@city.name}"
    @canonical = "https://www.zoomcar.com/#{@city.link_name}/search"
    if request.post?
      @booking = Booking.new
      @booking.city_id = @city.id
      @booking.starts = Time.zone.parse(params[:starts]) if !params[:starts].blank?
      @booking.ends = Time.zone.parse(params[:ends]) if !params[:ends].blank?
      @booking.location_id = params[:loc] if !params[:loc].blank?
      @booking.cargroup_id = params[:car] if !params[:car].blank?
      # @booking.valid?
      session[:search] = {:starts => params[:starts], :ends => params[:ends], :loc => params[:loc], :car => params[:car]}
      session[:deal] = nil
      if params[:id] == 'homepage'
        render json: {html: render_to_string('_widget_homepage.haml', layout: false)}
      else
        render json: {html: render_to_string('_widget.haml', layout: false)}
      end
    else
      redirect_to '/' and return if session[:search].blank?
      if @city.inactive?
      	@inventory,@cars = [nil,nil]
      	@header = 'search'
      else
	      @booking = Booking.new
	      @booking.city_id = @city.id
	      @booking.starts = Time.zone.parse(session[:search][:starts]) if !session[:search].blank? && !session[:search][:starts].blank?
	      @booking.ends = Time.zone.parse(session[:search][:ends]) if !session[:search].blank? && !session[:search][:ends].blank?
	      @booking.location_id = session[:search][:loc] if !session[:search].blank? && !session[:search][:loc].blank?
	      @booking.cargroup_id = session[:search][:car] if !session[:search].blank? && !session[:search][:car].blank?
		      Rails.logger.info "Calling admin for search results: ========"
		      search_results_from_admin = admin_api_get_call "#{admin_hostname}/mobile/#{admin_api_version}/bookings/search",
		                                                  {
		                                                              starts: session[:search][:starts],
		                                                              ends: session[:search][:ends],
		                                                              city: @city.link_name,
		                                                              location_id: @booking.location_id,
		                                                              platform: "web"
		                                                            }
		        Rails.logger.info "API call over: ======== "
		      	@inventory,@cars,@order = get_inventory_from_json search_results_from_admin
		      	@header = 'search'
		  end
    end
  end

  def show
    flash.keep
    render layout: 'users'
  end

  def thanks
    render layout: 'plain'
  end

  def timeline_bak
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

  def timeline
    if !params[:car].blank? && !params[:location].blank? && !session[:search].blank? && !session[:search][:starts].blank? && !session[:search][:ends].blank?
		@booking = Booking.new
		@booking.starts = Time.zone.parse(session[:search][:starts])
		@booking.ends = Time.zone.parse(session[:search][:ends])
		@booking.cargroup_id = params[:car]
		@booking.location_id = params[:location]
  		@page = (params[:page] || 0).to_i
  			
  		timeline_from_admin = admin_api_get_call "#{ADMIN_HOSTNAME}/mobile/#{ADMIN_API_VERSION}/bookings/timeline",
                                               {
                                                          starts: session[:search][:starts],
                                                          ends: session[:search][:ends],
                                                          city: "pune",
                                                          location: params[:location],
                                                          page: params[:page],
                                                          car: params[:car],
                                                          platform: "web"
                                                        }
 	 	@inventory,@cargroup,@location = get_timeline_inventory_from_json timeline_from_admin
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
		redirect_to do_bookings_path(@city.link_name.downcase) and return if !user_signed_in? || (current_user && current_user.check_details)
		check_deal
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
    redirect_to checkout_bookings_path(@city.link_name.downcase) if current_user && current_user.is_blacklisted? && current_user.is_underage?
  end

	def check_inventory
		if @booking && @booking.valid? && !(session[:deal].present?)
			if @booking.jsi.blank? && @booking.status == 0
				cargroup = @booking.cargroup
				@available = Inventory.do_check(@city.id, @booking.cargroup_id, @booking.location_id, (@booking.starts - cargroup.wait_period.minutes), (@booking.ends + cargroup.wait_period.minutes))
				if @available == 0 && !session[:notify].present?
					flash[:error] = "Sorry, but the car is no longer available"
					redirect_to(:back) and return
				end
			end
		elsif session[:deal].present?
			@available = 1
		end
	end

	def check_search
		if !session[:book].blank? && !session[:book][:starts].blank? && !session[:book][:ends].blank? && !session[:book][:car].blank? && !session[:book][:loc].blank?
			@booking = Booking.new
			@booking.starts = Time.zone.parse(session[:book][:starts])
			@booking.ends = Time.zone.parse(session[:book][:ends])
			@booking.location_id = session[:book][:loc]
			@booking.cargroup_id = session[:book][:car]
			city = @booking.location.city
			@booking.city_id = city.id
			@booking.valid?
			redirect_to request.fullpath.gsub(@city.link_name.downcase, city.link_name.downcase) and return if city.id != @city.id
		end
	end
	
	def check_search_access
		if !@booking || !@booking.valid?
			if request.xhr?
				render json: {html: "<div class='alert alert-danger' role='alert'>Bad Request!</div>"}
			else
				redirect_to search_path(@city.link_name.downcase)
			end
			return
		end
	end

	def check_promo
		session[:promo_code] = nil
		session[:promo_message] = nil
  	session[:promo_discount] = 0
  	session[:promo_valid] = false
	end

	def copy_params
		session[:book] = {} if session[:book].blank?
		session[:book][:starts] = params[:starts] if !params[:starts].blank?
		session[:book][:ends] = params[:ends] if !params[:ends].blank?
		session[:book][:loc] = params[:loc] if !params[:loc].blank?
		session[:book][:car] = params[:car] if !params[:car].blank?
		session[:book][:deposit] = params[:deposit].to_i if !params[:deposit].blank?
	end
	
	def image_params
		params.require(:image).permit(:avatar)
	end
	
	def feedback_params
		params.require(:review).permit(:comment, :rating_tech, :rating_friendly, :rating_condition, :rating_location)
	end

	def payu_test_params(amount, key )
		{"mihpayid"=>"4039937155099#{10000 + rand(99999)}", "mode"=>"CC", "status"=>"success", "unmappedstatus"=>"captured", "key"=>"C0Dr8m", "txnid"=>"1bdfe", "amount"=>"6500.00", "discount"=>"0.00", "net_amount_debit"=>"6500", "addedon"=>"2014-08-26 16:13:57", "productinfo"=>"Figo", "firstname"=>"fdsf", "lastname"=>"", "address1"=>"", "address2"=>"", "city"=>"", "state"=>"", "country"=>"", "zipcode"=>"", "email" => PAYU_EMAIL, "phone" => PAYU_PHONE, "udf1"=>"", "udf2"=>"", "udf3"=>"", "udf4"=>"", "udf5"=>"", "udf6"=>"", "udf7"=>"", "udf8"=>"", "udf9"=>"", "udf10"=>"", "hash"=>"5332219dcb4c07661a85d31e4a3da055cf4a63bea9c40c3e3866780bb424238464661868dfb8724816d89937e57867c8f47a2c13f32106078e0b1e50b42d0ed4", "field1"=>"187269", "field2"=>"423820564675", "field3"=>"20140826", "field4"=>"MC", "field5"=>"564675", "field6"=>"00", "field7"=>"0", "field8"=>"3DS", "field9"=>" Successful Verification of Secure Hash:  -- Approved -- Transaction Successful -- Unable to be determined--E219", "payment_source"=>"payu", "PG_TYPE"=>"AXIS", "bank_ref_num"=>"187269", "bankcode"=>"CC", "error"=>"E000", "error_Message"=>"No Error", "name_on_card"=>"ksdfh", "cardnum"=>"512345XXXXXX2346", "cardhash"=>"This field is no longer supported in postback params."}
	end

	# Loads booking object from db if already created
	#
	# Author::Aniket
	# Date:: 22/11/2014
	def check_booking_obj
		if session[:book].present? && session[:book][:id].present?
			b = Booking.find_by(id: CommonHelper.decode(session[:book][:id]))
			if b.starts == Time.zone.parse(session[:book][:starts]) && b.ends == Time.zone.parse(session[:book][:ends]) && b.location_id == session[:book][:loc].to_i && b.cargroup_id == session[:book][:car].to_i
				# @booking = Booking.new
				@booking = b.clone
				@booking.id = b.id
				@booking.starts = b.starts
				@booking.ends = b.ends
				@booking.location_id = b.location_id
				@booking.cargroup_id = b.cargroup_id
				@booking.city_id = b.city_id
				@booking
			else
				session[:book][:id] = nil
				nil
			end
		end
	end

	# Finds deal and creates a refund charge for discount amount if deal is valid and available
	# Author::Aniket
	def find_deal_and_create_charge(deal_code)
		str, id = CommonHelper.decode(deal_code)
		if str == 'deal' 
			@deal = Deal.find_by(id: id)
			if @deal.booking_id.blank? && !@deal.sold_out && @deal.starts == session[:book][:starts] && @deal.ends == session[:book][:ends] && @deal.cargroup_id.to_s == session[:book][:car] && @deal.location_id.to_s == session[:book][:loc]
				@booking.car_id = @deal.car_id
				return @booking.promo = 'SQUIRREL' + deal_code
			elsif @deal.booking_id.present? || @deal.sold_out
				flash.keep[:notice] = 'Deal has already been taken. Please check back again after some time.'
				"taken"
			else
				"nodeal"
			end
		end
	end

	# checks if deal is present and valid, updates promo column with 'SQUIRREL' if true
	# Author::Aniket
	def check_deal
		if session[:deal].present?
			str, id = CommonHelper.decode(session[:deal])
			if str == 'deal'
				deal = Deal.find_by(id: id)
				if deal.present? && deal.booking_id.blank? && !deal.sold_out && deal.starts == session[:book][:starts] && deal.ends == session[:book][:ends] && deal.cargroup_id == session[:book][:car] && deal.location_id == session[:book][:loc]
					@booking.promo = 'SQUIRREL'
					@discount = deal.discount
				end
			end
		end
	end

	def clear_credit_and_offers
		# Clear Session if user is on a different booking
		if session[:credits] && same_booking?
			apply_credits
		else
			session[:credits] = nil
			session[:credits_hash] = nil
		end
		booking = check_booking_obj
		# Clear Promos
		check_promo
		# Clear Promot and Credit Entries if Created by Seamless Checkout
		if booking
			booking.revert_credits
			booking.revert_promo
		end
	end

	# Applies credits to user booking
  #
  # Author:: Rohit
  # Date:: 22/10/2014
  #
	def apply_credits
		# make credits invalid if user does not have credits
		if current_user.total_credits.to_i <= 0 || !same_booking?
			session[:credits] = nil
			return
		end
			# recalcuate credits
		result = @booking.apply_credits(current_user.total_credits.to_i, session[:promo_discount].to_i)
    if result[:err].nil?
    	session[:credits] = result[:credits]
    	session[:credits_hash] = credits_hash
    end
	end

	def same_booking?
		session[:credits_hash] == credits_hash
	end
end
