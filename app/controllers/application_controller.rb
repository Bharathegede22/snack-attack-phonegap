class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  
  #protect_from_forgery with: :exception
  
  private
	
	def meta
		@meta_title = "Zoomcar"
		@meta_description = "Zoomcar User Account"
		@meta_keywords = "zoomcar"
		@noindex = true
	end
	
end
