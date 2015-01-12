module ApiModule

  def self.admin_api_post_call(url,params)
    begin
      resource = RestClient::Resource.new(url,:timeout => 5, :open_timeout => 5)
      response = resource.post params 
    rescue Exception => e
      Rails.logger.info "RestClient POST call failed\n #{e.message}"
      response = nil
    end
    JSON.parse(response) if response
  end

end