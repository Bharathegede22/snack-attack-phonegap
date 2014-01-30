class UsersController < ApplicationController
	
	before_filter :authenticate_user!, :only => [:social, :settings, :update]
	
	def forgot
		render json: {html: render_to_string('/devise/passwords/new.haml', :layout => false)}
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
			current_user.phone =  user.phone
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
		render json: {html: render_to_string('/users/status.haml', :layout => false)}
	end
	
	def update
		notice = ''
		error = ''
		if current_user.update(signup_params.merge({'profile' => 1}))
			notice = 'Profile changes are saved! '
		else
			error = 'Please fix the following error! '
		end
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
				notice << 'Thanks for uploading your license image.'
			else
				error << 'License image was not uploaded. Please fix the erros!'
			end
		end
		flash[:notice] = notice if !notice.blank?
		flash[:error] = error if !error.blank?
		if error.blank?
			redirect_to "/users/settings"
		else
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
