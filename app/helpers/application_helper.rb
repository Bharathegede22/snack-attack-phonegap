module ApplicationHelper

  def admin_api_get_call url,params
    begin
      resource = RestClient::Resource.new(url,:timeout => 30, :open_timeout => 5)
      resource.get params: params  
    rescue Exception => e
      Rails.logger.debug "RestClient GET call failed\n #{e.message}"
      ExceptionNotifier.notify_exception(e)
      flash[:error] = "Sorry, our system is busy right now. Please try after some time."
      return
    end
  end

  def admin_api_post_call url,params
    begin
      resource = RestClient::Resource.new(url,:timeout => 5, :open_timeout => 5)
      resource.post params
    rescue Exception => e
      Rails.logger.debug "RestClient POST call failed\n #{e.message}"
      ExceptionNotifier.notify_exception(e)
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

  def show_otp_verification_box?
    return false if current_user.blank?
    return false if params[:reenter_phone].present?
    return true if current_user.referral_sign_up? && current_user.phone.present? && !current_user.phone_verified
    return true if current_user.unverified_phone.present? && current_user.otp_valid_till.present? && (Time.now < current_user.otp_valid_till)
    false
  end
  

end
