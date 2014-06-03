class Users::OmniauthController < Devise::OmniauthCallbacksController 
	
	include Devise::Controllers::Rememberable
	
  def facebook
    manage
  end
  
  def linkedin
    manage
  end

  def google_oauth2
    manage
    # user = User.from_omniauth(request.env["omniauth.auth"])
    # if user.persisted?
    #   flash.notice = "Signed in Through Google!"
    #   sign_in_and_redirect "/"
    # else
    #   session["devise.user_attributes"] = user.attributes
    #   flash.notice = "You are almost Done! Please provide a password to finish setting up your account"
    #   redirect_to "/bookings/do" and return
    # end
  end
  
  private
  
  def manage
  	session[:social_signup], user = User.find_for_oauth(request.env["omniauth.auth"], current_user, session[:ref_initial], session[:ref_immediate])
  	if user
			sign_in('user', user)
			if session[:book].blank?
		 		redirect_to "/" and return
		 	else
		 		session[:social_signup] = nil
		 		redirect_to "/bookings/do" and return
		 	end
		else
			flash[:error] = "Sorry, we could not access your email id from facebook. Please signup using normal procees."
			if session[:book].blank?
		 		redirect_to "/" and return
		 	else
		 		redirect_to "/bookings/do" and return
		 	end
		end
  end

end
