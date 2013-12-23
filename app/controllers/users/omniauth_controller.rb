class Users::OmniauthController < Devise::OmniauthCallbacksController 
	
	include Devise::Controllers::Rememberable
	
  def facebook
    manage
  end
  
  def linkedin
    manage
  end
  
  private
  
  def manage
  	session[:social_signup], user = User.find_for_oauth(request.env["omniauth.auth"], current_user)
  	remember_me(user)
  	sign_in('user', user)
  	if session[:book].blank?
   		redirect_to "/" and return
   	else
   		redirect_to "/bookings/do" and return
   	end
  end

end
