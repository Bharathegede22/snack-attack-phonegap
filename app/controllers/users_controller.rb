class UsersController < ApplicationController
	
	before_filter :authenticate_user!, :only => [:license,:license_get_del, :social, :settings, :update, :credits, :referrals,:credit_history]
	skip_before_filter :authenticate_staging
	
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
				if params[:image_id].present? && !current_user.license_pic.blank?
					img = Image.where("imageable_id = ? AND id = ? AND imageable_type = 'License'", current_user.id,params[:image_id].to_i)
					all_pics = Image.where("imageable_id = ? AND imageable_type = 'License'",current_user.id)
					image_count = all_pics.count if !all_pics.blank?
					if img.present?
						img.first.avatar.destroy
						if img.first.destroy
							image_count = image_count - 1
							# image_arr << {delete_status: 1, count: image_count}
							# last_count = Image.where("imageable_id = ? AND imageable_type = 'License'",current_user.id)
							if image_count == 0
								User.find(current_user.id).update_column(:license_status,0)
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
    	image = Image.where("imageable_id = ? AND imageable_type = 'License'",current_user.id)
    	if image.blank?
    		image_count = 0 
    	else
    		image_count = image.count
    	end
	    @image_arr << {count: image_count,status: current_user.license_status}
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
		   	image_count = Image.where("imageable_id = ? AND imageable_type = 'License'",current_user.id).count
		   	if image_count < 5 
			   	@image = Image.new(image_params)
					@image.imageable_id = current_user.id
					@image.imageable_type = 'License'
					if @image.save
						image_count = (image_count + 1)
						current_user.license_status = 1
						current_user.save(:validate=>false)
				    @image_arr << {count: image_count,status: current_user.license_status}
		    		# urll = "http://local.dev"
		   	  	urll = @image.avatar.url
		   	  	@image_arr << {url: urll, image_id: @image.id}
		   	  else
		   	  	@image_arr << {count: image_count,status: current_user.license_status,error: 1}
				  end
			      @hash = {image: @image_arr}
			      render :json => @hash
			 	else
			 			@image_arr << {count: image_count,status: current_user.license_status,error: 0}
			 			
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
      #if current_user.city_id.blank?
      # current_user.city_id = @city.id
      #else
      # current_user.city = user.city
      #end
			current_user.city = user.city
      current_user.city_id = user.city_id
			current_user.signup = true
			if current_user.save
				flash[:notice] = 'Details saved, please carry on!' if session[:book].blank?
			else
				flash[:error] = 'Please fix the following errors.'
			end
			return render json: {html: render_to_string('/users/signup.haml', :layout => false)}
		else
			if user_signed_in?
				return render json: {html: render_to_string('/users/signup.haml', :layout => false)}
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
		p @city.inspect
		render json: {html: render_to_string('/users/status.haml', :layout => false)}
	end

	def status_old
		p @city.inspect
		render json: {html: render_to_string('/users/status_old.haml', :layout => false)}
	end

	def update
		if current_user.update(signup_params.merge({'profile' => 1}))
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
		args = { platform: "web", auth_token: current_user.authentication_token, :referral_email => params[:email], :source => 'email'}
    url = "#{ADMIN_HOSTNAME}/mobile/v3/users/invite_user"
    response = ApiModule.admin_api_post_call(url, args)
		render json: (response["response"] rescue { err: true, :response => 'Sorry!! But something went wrong'})
	end
	
	private
	
	def image_params
		params.permit(:avatar)
	end
	
  def signup_params
    params.require(:user).permit(:name, :phone, :dob, :gender, :country, :pincode, :state, :city, :license, :city_id)
  end

end
