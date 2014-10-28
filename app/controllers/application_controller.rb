require "browser"
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  
  #protect_from_forgery with: :exception
  
  before_filter :check_city
  before_filter :check_mobile
  before_filter :check_ref
  before_filter :authenticate_staging

  def abtest?
    !cookies[:abtestd].blank?
  end

  def check_city
    # Checking explicit city in the url
    city_prompt = false
    city = params[:city]
    if city
      city = city.downcase
      @cityp = City.lookup(city)
    end
    
    # Fallback ip detect
    if city.blank?
	    if session[:city]
	      city = session[:city]
	    elsif cookies[:city]
	      city = cookies[:city]
	    else
	    	city_prompt = true
	      ip = request.headers["X-Real-IP"] if request.headers["X-Real-IP"] && !request.headers["X-Real-IP"].empty?
	      city = get_city_from_ip(ip) if ip
        city = 'bangalore' if city.blank?
	    end
    end
    if city_prompt
    	@city = City.lookup(city.downcase)
    else
    	set_cookies_ref(city)
		end
  end

  def check_invite
    # Checking for invitation
    if !params[:from].blank?
			session[:from] = params[:from]
			cookies.permanent.signed[:from] = params[:from]
		else
			session[:from] = cookies.signed[:from] if session[:from].blank?
		end
  end
  
  def check_mobile
  	session[:web_layout] = 1 if !params[:web].blank? && params[:web].to_i == 1
  	return if !session[:web_layout].blank? && session[:web_layout] == 1
  	# Checking mobile browsers
  	if !request.user_agent.blank?
  		browser = Browser.new(:ua => request.user_agent, :accept_language => "en-us")
  		if browser.mobile? || browser.tablet?
  			if browser.mac?
  				@device = 'ios'
  			else
  				@device = 'android'
  			end
  		end
  	end
  end
  
  def check_ref
    response.headers["X-FRAME-OPTIONS"] = "ALLOW-FROM http://optimizely.com"
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
  
  def check_ubid
  	# Assigning unique browser id
  	if session[:ubid].blank?
 			cookies.permanent.signed[:zcubid] = request.session_options[:id] if cookies.signed[:zcubid].blank?
 			session[:ubid] = cookies.signed[:zcubid]
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

  def authenticate_staging
    redirect_to '/users/access' and return if Rails.env == 'staging' && (current_user.blank? || (!current_user.blank? && current_user.role < 1))
  end
  
  private
  
  def get_city_from_ip(ip)
    geo = GeoIP.new(::Rails.root + "GeoLiteCity.dat").city(ip)
    return get_city(geo.latitude, geo.longitude) if geo && geo.country_name == 'India'
  end
  
  def get_city(lat,lon)
	  #if lat >= 22.8333 && lat <= 23.2333 && lon >= 72.4167 && lon <= 72.8167 
    #  city = 'ahmedabad'
    #elsif lat >= 30.38 && lat <= 31.08 && lon >= 76.46 && lon <= 77.14
    #  city = 'chandigarh'
    #elsif lat >= 12.73 && lat <= 13.43 && lon >= 79.93 && lon <= 80.63
    #  city = 'chennai'
    #elsif lat >= 28.32 && lat <= 29.02 && lon >= 76.87 && lon <= 77.57
    #  city = 'delhi'
    #elsif lat >= 17.03 && lat <= 17.73 && lon >= 78.12 && lon <= 78.82
    #  city = 'hyderabad'
    #elsif lat >= 26.7167 && lat <= 27.1167 && lon >= 75.6167 && lon <= 76.0167 
    #  city = 'jaipur'
    #elsif lat >= 22.22 && lat <= 22.92 && lon >= 88.02 && lon <= 88.72
    #  city = 'kolkata'
    #elsif lat >= 18.63 && lat <= 19.33 && lon >= 72.48 && lon <= 73.18
    #  city = 'mumbai'
    if lat >= 18.18 && lat <= 18.88 && lon >= 73.52 && lon <= 74.22
      city = 'pune'
    else
      city = 'bangalore'
    end
    return city
  end
	
	def set_cookies_ref(city)
    session[:city] = city.downcase
    cookies[:city] = {:value => city.downcase, :expires => 10.years.from_now, :domain => ".#{HOSTNAME.split(':').first}"}
    @city = City.lookup(city.downcase)
  end
  
end
