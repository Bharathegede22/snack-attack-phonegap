module ApiModule

  def self.admin_api_post_call(url,params)
    begin
      resource = RestClient::Resource.new(url,:timeout => 5, :open_timeout => 5)
      resource.post params  
    rescue Exception => e
      Rails.logger.info "RestClient POST call failed\n #{e.message}"
      #flash[:error] = "Sorry, our system is busy right now. Please try after some time."
    end
  end

end