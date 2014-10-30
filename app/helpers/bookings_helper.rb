module BookingsHelper

  def admin_hostname
   ADMIN_HOSTNAME 
  end

  def admin_api_version
    ADMIN_API_VERSION
  end

  def admin_api_get_call url,params
    RestClient.get url,params 
  end

  def admin_api_post_call url,params
    RestClient.post url,params 
  end
end
