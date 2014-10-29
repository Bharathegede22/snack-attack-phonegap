class Users::SessionsController < Devise::SessionsController
	
	skip_before_filter :authenticate_staging

	def create
		if request.xhr?
			resource = warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
			sign_in_and_redirect(resource_name, resource)
		else
			self.resource = warden.authenticate!(auth_options)
			set_flash_message(:notice, :signed_in) if is_flashing_format?
			sign_in(resource_name, resource)
			yield resource if block_given?
			respond_with resource, :location => after_sign_in_path_for(resource)
		end
  end
 
 	def new
 		respond_to do |format|
			format.html {
				self.resource = resource_class.new(sign_in_params)
				clean_up_passwords(resource)
				session[:blocked] = 1
				redirect_to "/" and return
				#respond_with(resource, serialize_options(resource))
			}
			format.json {
				self.resource = resource_class.new(sign_in_params)
				clean_up_passwords(resource)
				render json: {html: render_to_string('new.haml', :layout => false)}
			}
		end
  end
  
  def sign_in_and_redirect(resource_or_scope, resource=nil)
    scope = Devise::Mapping.find_scope!(resource_or_scope)
    resource ||= resource_or_scope
    sign_in(scope, resource) unless warden.user(scope) == resource
    if !session[:book].blank?
    	respond_to do |format|
	  		format.json {render json: {html: render_to_string('/users/wait.haml', layout: false)}}
	  	end
	  else
		  respond_to do |format|
				format.json {render json: {html: render_to_string('/users/signin.haml', :layout => false)}}
			end
		end
  end
 
  def failure
  	respond_to do |format|
			format.json {
				flash[:error] = 'Invalid Password'
				render json: {html: render_to_string('new.haml', :layout => false)}
			}
		end
  end
  
  def destroy
  	if request.xhr?
  		signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
  		respond_to do |format|
		    format.json {render json: {html: render_to_string('/users/signout.haml', :layout => false)}}
		  end
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
