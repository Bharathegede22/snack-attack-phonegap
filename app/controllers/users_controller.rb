class UsersController < ApplicationController
	
	before_filter :authenticate_user!, :only => [:license, :social, :settings, :update, :credits]
	
	def credits
		@total_credits = current_user.total_credits
	    @earned_credits = current_user.credits.where(:action=> true).order(:created_at => :desc)
	    @used_credits = current_user.credits.where(:action=> false).order(:created_at => :desc)
	end

	def forgot
		render json: {html: render_to_string('/devise/passwords/new.haml', :layout => false)}
	end
	
	def license
		if request.post?
			if !params[:image].blank?
				@image = current_user.license_pic
				if @image
					@image.update(image_params)
				else
					@image = Image.new(image_params)
					@image.imageable_id = current_user.id
					@image.imageable_type = 'License'
					@image.save
				end
				if @image.valid?
					current_user.update_attribute(:license_status, 1)
					BookingMailer.delay.license_update(current_user.id)
					flash[:notice] = 'Thanks for uploading your driving license image.'
					current_user.license_status = 1
					current_user.save!
					#@step = (params[:step].to_i + 1).to_s if !params[:step].blank?
				else
					if @image.errors[:avatar_content_type].length > 0
						flash[:error] = 'Please attach a valid license image. Only allow formats are jpg, jpeg, gif and png.'
					else
						flash[:error] = 'Please attach a valid license image. Maximum allowed file size is 2 MB.'
					end
				end
			else
				flash[:error] = 'Please attach a license image'
			end
		# else
		# 	@step = params[:step]
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
	
	def update
		if current_user.update(signup_params.merge({'profile' => 1}))
			flash[:notice] = 'Profile changes are saved! '
			redirect_to "/users/settings"
		else
			flash[:error] = 'Please fix the following error! '
			render 'settings'
		end
	end
	
	private
	
	def image_params
		params.require(:image).permit(:avatar)
	end
	
  def signup_params
    params.require(:user).permit(:name, :phone, :dob, :gender, :country, :pincode, :state, :city, :license)
  end
  
end
