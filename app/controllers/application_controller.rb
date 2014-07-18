class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  
  #protect_from_forgery with: :exception
  
  before_filter :check_city
  before_filter :check_ref
  
  def check_city
    # Checking explicit city in the url
    city_prompt = false
    city = params[:city]
    city = city.downcase if city
    
    # Fallback ip detect
    if city.blank?
	    if session[:city]
	      city = session[:city]
	    elsif cookies[:city]
	      city = cookies[:city]
	    else
	    	city_prompt = true
	      ip = request.headers["X-Real-IP"] if request.headers["X-Real-IP"] && !request.headers["X-Real-IP"].empty?
	      if ip
	        city = get_city_from_ip(ip)
	      else
	        city = 'bangalore'
	      end
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
  	# Checking mobile browsers
  	session[:mobile_layout] = 1 if !session[:wap_layout] && !request.user_agent.blank? && (/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.match(request.user_agent) || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.match(request.user_agent[0..3]))
  	session[:mobile_layout] = 1 if !params[:ref].blank? && params[:ref] == 'gomobile'
  	session[:mobile_layout] = 0 if !session[:wap_layout]
  end
  
  def check_ref
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
