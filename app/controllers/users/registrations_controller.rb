class Users::RegistrationsController < Devise::RegistrationsController
	
	#prepend_before_filter :require_no_authentication, :only => [ :new, :cancel ]
	
	def create
    build_resource(sign_up_params)
    if resource.save
      yield resource if block_given?
      if resource.active_for_authentication?
        #set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
        flash[:notice] = "<b>Thanks for signing up</b>. Please provide the following details."
        session[:normal_signup] = 1
				return render json: {html: render_to_string('/users/signup.haml', layout: false)}
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      return render json: {html: render_to_string('/devise/registrations/new.haml', layout: false)}
    end
  end
  
end
