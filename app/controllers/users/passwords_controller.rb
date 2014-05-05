class Users::PasswordsController < Devise::PasswordsController
	
	def create
		if request.xhr?
			self.resource = resource_class.send_reset_password_instructions(resource_params)
			yield resource if block_given?
			respond_to do |format|
    		format.json {
					if successfully_sent?(resource)
						flash[:notice] = "Password reset instructions are emailed to <b>#{resource.email}</b>."
						render json: {html: render_to_string('new.haml', layout: false), emailSent: 1}
					else
						render json: {html: render_to_string('new.haml', layout: false), emailSent: 0}
					end
    		}
    	end
		else
			self.resource = resource_class.send_reset_password_instructions(resource_params)
			yield resource if block_given?
			if successfully_sent?(resource)
			  respond_with({}, :location => after_sending_reset_password_instructions_path_for(resource_name))
			else
			  respond_with(resource)
			end
		end
  end
  
  protected
  
  def after_resetting_password_path_for(resource)
    "/users/settings"
  end
  
end
