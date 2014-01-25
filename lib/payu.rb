require 'rest_client'
module Payu
  class << self
    def check_status(id)
    	cmd = 'verify_payment'
    	hash = Digest::SHA512.hexdigest(PAYU_KEY + "|" + cmd + "|" + id + "|" + PAYU_SALT)
      resp = RestClient.post PAYU_API, 'key' => PAYU_KEY, 'command' => cmd, 'hash' => hash, 'var1' => id
      resp = JSON.parse(resp)
      if resp['status'] == 1
      	resp['transaction_details'].each do |k,v|
	    		str,id = CommonHelper.decode(k.downcase)
	    		if !str.blank? && str == 'payment'
						payment = Payment.find(id)
						payment.change_status(v) if payment
					end
				end
      end
    end
  end  
end
