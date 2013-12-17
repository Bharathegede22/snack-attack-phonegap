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
				flash[:notice] = 'Details saved, please carry on!'
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
		if current_user.update(signup_params)
			flash[:notice] = 'Changes saved!'
			redirect_to '/users/settings'
		else
			flash[:error] = 'Please fix the following error!'
			render 'settings'
		end
	end
	
	private

  def signup_params
    params.require(:user).permit(:name, :phone, :dob, :gender, :country, :pincode, :state, :city)
  end
  
end
