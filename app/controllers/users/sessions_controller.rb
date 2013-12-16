class Users::SessionsController < Devise::SessionsController
	
	def create
		resource = warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
		sign_in_and_redirect(resource_name, resource)
  end
 
  def sign_in_and_redirect(resource_or_scope, resource=nil)
    scope = Devise::Mapping.find_scope!(resource_or_scope)
    resource ||= resource_or_scope
    sign_in(scope, resource) unless warden.user(scope) == resource
    return render json: {html: render_to_string('/users/signin.haml', :layout => false)}
  end
 
  def failure
  	flash[:error] = 'Invalid Password'
  	return render json: {html: render_to_string('new.haml', :layout => false)}
  end
  
  def destroy
  	if request.xhr?
  		signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
  		return render json: {html: render_to_string('/users/signout.haml', :layout => false)}
  	else
		  redirect_path = after_sign_out_path_for(resource_name)
		  signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
		  set_flash_message :notice, :signed_out if signed_out && is_flashing_format?
		  yield resource if block_given?

		  # We actually need to hardcode this as Rails default responder doesn't
		  # support returning empty response on GET request
		  respond_to do |format|
		    format.all { head :no_content }
		    format.any(*navigational_formats) { redirect_to redirect_path }
		  end
		end
  end
  
end
