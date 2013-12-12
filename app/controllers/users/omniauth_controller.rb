class Users::OmniauthController < Devise::OmniauthCallbacksController 

  def facebook
    manage
  end
  
  def linkedin
    manage
  end
  
  private
  
  def manage
  	@user = User.find_for_oauth(request.env["omniauth.auth"], current_user)
    if current_user
    	sign_in_and_redirect @user
    else
    	sign_in_and_redirect @user
    end
  end

end
