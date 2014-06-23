class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  
  #protect_from_forgery with: :exception
  
  before_filter :check_city
  before_filter :check_params
  
  def check_city
    if !params[:city].blank?
      @city = Rails.cache.fetch('current_city') {City.find_by_name(params[:city])} 
    else
      @city = City.find_by_name(DEFAULT_CITY)
    end
    cookies[:city] = {:value=>@city.name, :expires => 30.days.from_now, :domain => ".#{HOSTNAME.gsub('www.','')}"}
  end

  def check_params
  	# Check Ref Initial
  	if cookies[:ref].blank?
  		vref = ''
  	else
  		vref = cookies[:ref] + ','
  	end
  	vref << params[:ref] + ',' if !params[:ref].blank?
  	if vref.blank?
  		vref ='-'
  	else
  		vref = vref.split(',').uniq.join(',')
  		if vref.split(',').length > 5
  			tmp = vref.split(',')
  			vref = tmp[0]
  			vref << ',' + ((tmp.reverse - [vref])[0..3].reverse).join(',')
  		end
  	end
  	cookies[:ref] = {:value => vref, :expires => 30.days.from_now, :domain => ".#{HOSTNAME.gsub('www.','')}"}
  	session[:ref_initial] = cookies[:ref]
  	
  	# Check Ref Immediate
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
