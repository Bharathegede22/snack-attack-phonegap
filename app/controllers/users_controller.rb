class UsersController < ApplicationController
	
	before_filter :authenticate_user!, :only => [:license,:license_get_del, :social, :settings, :update, :credits, :referrals,:credit_history]
	skip_before_filter :authenticate_staging
	before_filter :check_license, :only => [:license,:license_get_del]
	
	def access
		flash[:error] = "<b>Access Denied!</b>"
	end

	# Shows User Credits in the modal box
	def credit_history
    @total_credits = current_user.total_credits
    @user_credits = current_user.credits.order(:created_at => :desc).to_a
    render json: {html: render_to_string('_credit_history.haml', layout: false)}
	end

	def forgot
		render json: {html: render_to_string('/devise/passwords/new.haml', :layout => false)}
	end
	
	def license_get_del
		if params[:license_delete] == "true"
				@hash = {}
				image_arr = []
				image_count = 0
				if params[:image_id].present? && !@admin_user.license_pic.blank?
					img = Image.where("imageable_id = ? AND id = ? AND imageable_type = 'License'", @admin_user.id,params[:image_id].to_i)
					all_pics = Image.where("imageable_id = ? AND imageable_type = 'License'",@admin_user.id)
					image_count = all_pics.count if !all_pics.blank?
					if img.present?
						img.first.avatar.destroy
						if img.first.destroy
							image_count = image_count - 1
							# image_arr << {delete_status: 1, count: image_count}
							# last_count = Image.where("imageable_id = ? AND imageable_type = 'License'",@admin_user.id)
							if image_count == 0
								User.find(@admin_user.id).update_column(:license_status,0)
								image_arr << {delete_status: 1, count: image_count,final_status: 0}
							else
								image_arr << {delete_status: 1, count: image_count,final_status: 1}
							end
						end	
					end
				else
					image_arr << {delete_status: 0, count: image_count}	
				end
				@hash = {image: image_arr}
				render :json => @hash
		else
			@hash = {}
    	@image_arr = []
    	image_count = 0
    	count = 0
    	image = Image.where("imageable_id = ? AND imageable_type = 'License'",@admin_user.id)
    	if image.blank?
    		image_count = 0 
    	else
    		image_count = image.count
    	end
	    @image_arr << {count: image_count,status: @admin_user.license_status}
	    if !image.blank?
	    	image.each do|img|
	    	# urll = "http://local.dev"
	   	  	urll = img.avatar.url
	   	  	@image_arr << {url: urll, image_id: img.id}
	   	  	# count = count + 1
	  		end
	    end
			@hash = {image: @image_arr}
	   	render :json => @hash
	  end
	end

	def license			
    if request.post? 
	      @hash = {}
	      @image_arr = []
	      count = 0
		   	image_count = Image.where("imageable_id = ? AND imageable_type = 'License'",@admin_user.id).count
		   	if image_count < 5 
			   	@image = Image.new(image_params)
					@image.imageable_id = @admin_user.id
					@image.imageable_type = 'License'
					if @image.save
						image_count = (image_count + 1)
						@admin_user.license_status = 1
						@admin_user.save(:validate=>false)
				    @image_arr << {count: image_count,status: @admin_user.license_status}
		    		# urll = "http://local.dev"
		   	  	urll = @image.avatar.url
		   	  	@image_arr << {url: urll, image_id: @image.id}
		   	  else
		   	  	@image_arr << {count: image_count,status: @admin_user.license_status,error: 1}
				  end
			      @hash = {image: @image_arr}
			      render :json => @hash
			 	else
			 			@image_arr << {count: image_count,status: @admin_user.license_status,error: 0}
			 			
			    	####
			  end
	  end
  end
	
	def signin
		if user_signed_in?
			return render json: {html: render_to_string('/users/signup.haml', :layout => false)}
		else
			render json: {html: render_to_string('/devise/sessions/new.haml', :layout => false)}
		end
	end
	
	def signup
		if request.post?
			user = User.new(signup_params)
			current_user.name = user.name
			current_user.phone = user.phone
			current_user.dob = user.dob
			current_user.gender = user.gender
			current_user.country = user.country
			current_user.pincode = user.pincode
			current_user.state = user.state

			current_user.city = user.city
      current_user.city_id = user.city_id
			current_user.signup = true
			if current_user.save
				# Send OTP verification sms to user mobile phone
				call_send_otp_sms_api if current_user.referral_sign_up?
				flash[:notice] = 'Details saved, please carry on!' if session[:book].blank?
				return render json: {html: render_to_string('/users/otp_verification.haml', :layout => false)} if current_user.referral_sign_up?
			else
				flash[:error] = 'Please fix the following errors.'
			end
			return render json: {html: render_to_string('/users/signup.haml', :layout => false)}
		else
			if user_signed_in?
				if show_otp_verification_box?
					return render json: {html: render_to_string('/users/otp_verification.haml', :layout => false)}
				else
					return render json: {html: render_to_string('/users/signup.haml', :layout => false)}
				end
			else
				render json: {html: render_to_string('/devise/registrations/new.haml', :layout => false)}
			end
		end
	end
	
	def social
		session[:social_signup] = nil
		flash[:notice] = "<b>Thanks for signing up</b>. Please provide the following details."
		return render json: {html: render_to_string('/users/signup.haml', :layout => false)}
	end
	
	def status
		check_ref
		#set_city
		p @city.inspect
		render json: {html: render_to_string('/users/status.haml', :layout => false)}
	end

	def update
		attributes = signup_params
		attributes = attributes.merge("unverified_phone" => attributes["phone"]).except("phone") if current_user.phone.present? && current_user.phone != attributes["phone"]
		current_user.signup = true
		if current_user.update(attributes.merge({'profile' => 1}))
			if attributes["unverified_phone"].present?
				# Send OTP verification sms to the new user mobile phone
				call_send_otp_sms_api
				@show_otp_modal_box = true
			end
			flash[:notice] = 'Profile changes are saved! '
			redirect_to "/users/settings"
		else
			flash[:error] = 'Please fix the following error! '
			render 'settings'
		end
	end

	# Referral Page
  #
  # Author:: Rohit
  # Date:: 17/12/2014
  #
	def referrals
		render :layout => 'application'
	end

	# Applies referral
  #
  # Author:: Rohit
  # Date:: 17/12/2014
  #
  # Expects ::
  #  * <b>params[:referral_email]</b> comma separated email addresses to send referral emails
  #
	def refer_user
		args = { platform: "web", auth_token: current_user.generate_authentication_token, :referral_email => params[:email], :source => 'email'}
    url = "#{ADMIN_HOSTNAME}/mobile/v3/users/invite_user"
    response = ApiModule.admin_api_post_call(url, args)
		render json: (response["response"] rescue { err: true, :response => 'Sorry!! But something went wrong'})
	end

	# Sends OTP SMS to the user mobile
  #
  # Author:: Rohit
  # Date:: 19/02/2015
  #
	def send_otp_sms
		return unless request.xhr?
    response = call_send_otp_sms_api
		render json: {success: true}, :status => 200
	end

	# Applies referral
  #
  # Author:: Rohit
  # Date:: 17/12/2014
  #
  # Expects ::
  #  * <b>params[:otp_code]</b> OTP code to be verified from the user
  #
	def verify_opt_sms
		return unless request.xhr?
		response = call_verify_otp_sms_api
		@response = response["response"]["response"] rescue false
		@errors =  I18n.t response["response"]["err"] if response.present? && response["response"].present? && response["response"]["err"].present?
		# render json: (response["response"] rescue { err: true, :response => 'Sorry!! But something went wrong'})
		return render json: {html: render_to_string('/users/otp_verification.haml', :layout => false)}
	end

	
	private

	def check_license
		if params['license_approval_id'].present? && current_user.role >= 6
			cookies['license_approval_id'] = {:value => params['license_approval_id'].to_i, :expires => 5.minutes.from_now, :domain => ".#{HOSTNAME.gsub('www.','')}"}
		end
		if cookies['license_approval_id'].present?
	    @admin_user = User.where(id: cookies['license_approval_id'].to_i).first
	  else
	  	@admin_user = current_user
	  end
	end
	
	def image_params
		params.permit(:avatar)
	end
	
  def signup_params
    params.require(:user).permit(:name, :phone, :dob, :gender, :country, :pincode, :state, :city, :license, :city_id, :unverified_phone)
  end

end
