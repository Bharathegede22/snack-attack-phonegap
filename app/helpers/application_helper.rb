module ApplicationHelper

  def admin_api_get_call url,params
    begin
      resource = RestClient::Resource.new(url,:timeout => 30, :open_timeout => 5)
      resource.get params: params  
    rescue Exception => e
      Rails.logger.info "RestClient GET call failed\n #{e.message}"
      flash[:error] = "Sorry, our system is busy right now. Please try after some time."
      return
    end
  end

  def admin_api_post_call url,params
    begin
      resource = RestClient::Resource.new(url,:timeout => 5, :open_timeout => 5)
      resource.post params: params  
    rescue Exception => e
      Rails.logger.info "RestClient POST call failed\n #{e.message}"
      flash[:error] = "Sorry, our system is busy right now. Please try after some time."
    end
  end
	
	def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
  
  def errortxt(txt)
  	if !txt.blank?
  		return ("<p>" + txt + "</p>").html_safe
  	else
  		return ''
  	end
  end
  
  def render_flash
  	concat content_tag(:div, raw(flash[:notice]), :class => "alert alert-success") if flash[:notice] && !flash[:notice].empty?
  	concat content_tag(:div, raw(flash[:error]), :class => "alert alert-danger") if flash[:error] && !flash[:error].empty?
  	flash[:error] = flash[:notice] = nil
  end
  
	def resource_name
    :user
  end
 	
  def resource
    @resource ||= User.new
  end
 	
 	def show_currency(text)
 		number_with_delimiter(text.to_i, locale: 'en-IN')
 	end

  def referral_url(source)
    "http://#{HOSTNAME}/signup/?ref=#{Referral::REFCODE}&ref_code=#{current_user.referral_code}&refsource=#{source}"
  end
end
