require 'rest_client'
module Payu
  class << self
    def check_status(id)
    	begin
		  	cmd = 'verify_payment'
		  	hash = Digest::SHA512.hexdigest(PAYU_KEY + "|" + cmd + "|" + id + "|" + PAYU_SALT)
		    resp = RestClient.post PAYU_API, 'key' => PAYU_KEY, 'command' => cmd, 'hash' => hash, 'var1' => id
		    resp = JSON.parse(resp)
		  rescue Exception => e
		  	resp = nil
		  end
      return resp
    end
  end  
end
