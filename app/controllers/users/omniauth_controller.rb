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
    if current_user
    	sign_in_and_redirect user
    else
    	sign_in_and_redirect user
    end
  end

end
