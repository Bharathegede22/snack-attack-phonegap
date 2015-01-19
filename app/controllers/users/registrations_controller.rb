class Users::RegistrationsController < Devise::RegistrationsController
	
	def create
		if request.xhr?
			build_resource(sign_up_params)
			resource.ref_initial = session[:ref_initial]
			resource.ref_immediate = session[:ref_immediate]
			resource.city_id = params[:user][:city_id].to_i if !params[:user][:city_id].blank?
			if resource.save
				resource.generate_authentication_token
				validate_and_apply_referral(resource)
			  yield resource if block_given?
			  if resource.active_for_authentication?
			    #set_flash_message :notice, :signed_up if is_flashing_format?
			    sign_up(resource_name, resource)
			    if !session[:book].blank?
			    	respond_to do |format|
				  		format.json {render json: {html: render_to_string('/users/wait.haml', layout: false)}}
				  	end
				  else
						flash[:notice] = "<b>Thanks for signing up</b>. Please provide the following details."
						session[:normal_signup] = 1
						respond_to do |format|
							format.json {render json: {html: render_to_string('/users/signup.haml', layout: false)}}
						end
					end
			  else
			    set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
			    expire_data_after_sign_in!
			    respond_with resource, :location => after_inactive_sign_up_path_for(resource)
			  end
			else
			  clean_up_passwords resource
			  respond_to do |format|
		    	format.json {render json: {html: render_to_string('/devise/registrations/new.haml', layout: false)}}
		    end
			end
		else
			build_resource(sign_up_params)
			if resource.save
				resource.generate_authentication_token
				validate_and_apply_referral(resource)
			  yield resource if block_given?
			  if resource.active_for_authentication?
			    set_flash_message :notice, :signed_up if is_flashing_format?
			    sign_up(resource_name, resource)
			    respond_with resource, :location => after_sign_up_path_for(resource)
			  else
			    set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
			    expire_data_after_sign_in!
			    respond_with resource, :location => after_inactive_sign_up_path_for(resource)
			  end
			else
			  clean_up_passwords resource
			  respond_with resource
			end
		end
  end
  
  protected
  
  def after_update_path_for(resource)
  	"/users/settings"
  end
  
end
