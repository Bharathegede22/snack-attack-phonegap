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
		 		redirect_to do_bookings_path(session[:city]) and return
		 	end
		else
			flash[:error] = "Sorry, we could not access your email id from facebook. Please signup using normal procees."
			if session[:book].blank?
		 		redirect_to "/" and return
		 	else
		 		redirect_to do_bookings_path(session[:city]) and return
		 	end
		end
  end

end
