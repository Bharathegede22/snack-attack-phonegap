class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  
  #protect_from_forgery with: :exception
  
  before_filter :check_params
  
  def check_params
  	# Check City
  	@city = City.find_by_name(params[:city]) if !params[:city].blank?
  	# Check Ref
  	if cookies[:ref].blank?
  		if !params[:ref].blank?
  			cookies[:ref] = {:value => params[:ref], :expires => 30.days.from_now, :domain => ".#{HOSTNAME.gsub('www.','')}"}
  		else
  			cookies[:ref] = {:value => '-', :expires => 30.days.from_now, :domain => ".#{HOSTNAME.gsub('www.','')}"}
  		end
  	end
  	session[:ref_initial] = cookies[:ref] if session[:ref_initial].nil?
  	if !params[:ref].blank?
    	session[:ref_immediate] = params[:ref]
    else
    	session[:ref_immediate] = '-' if session[:ref_immediate].blank?
    end
  end
  
  def generic_meta
  	@meta_title = "Zoomcar"
		@meta_description = "Zoomcar"
		@meta_keywords = "zoomcar"
		@noindex
  end
  
  def render_404
  	render :file => Rails.root.join("public/404.html"),  :status => 404, :layout => nil
  end
  
end
