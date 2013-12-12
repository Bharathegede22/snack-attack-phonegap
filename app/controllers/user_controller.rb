class UserController < ApplicationController
	
	def login
		render json: {html: render_to_string('login.haml')}
	end
	
end
