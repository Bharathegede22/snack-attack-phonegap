class Users::PasswordsController < Devise::PasswordsController
	
	def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      flash[:notice] = "Password reset instructins are emailed to <b>#{resource.email}</b>."
  		return render json: {html: render_to_string('new.haml', layout: false)}
    else
      return render json: {html: render_to_string('new.haml', layout: false)}
    end
  end
  
end
