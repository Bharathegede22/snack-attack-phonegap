require 'rest_client'
module Juspay

	def self.check_status(id)
		begin
			response = RestClient::Request.execute(:url => "https://#{JUSPAY_API_KEY}:@api.juspay.in/order/status", :ssl_version => 'TLSv1_2', :method => 'post', :payload => {order_id: id})
		rescue Exception => e
			response = nil
		end
		response = JSON.parse(response)
		return response
	end	

	def self.create_order(data)
		begin
			response = RestClient::Request.execute(:url => "https://#{JUSPAY_API_KEY}:@api.juspay.in/order/create", :ssl_version => 'TLSv1_2', :method => 'post', :payload => data)
		rescue Exception => e
			# response = e.response
			response = {:status => 'error'}.to_json
		end
		response = JSON.parse(response)
		return response
	end

	def self.refund(id, amt)
		begin
			response = RestClient::Request.execute(:url => "https://#{JUSPAY_API_KEY}:@api.juspay.in/order/refund", :ssl_version => 'TLSv1_2', :method => 'post', :payload => {order_id: id, amount: amt})
		rescue Exception => e
			response = e.response
		end
		response = JSON.parse(response)
		return response
	end

	def self.update_order(data)
		begin
			response = RestClient::Request.execute(:url => "https://#{JUSPAY_API_KEY}:@api.juspay.in/order/update", :ssl_version => 'TLSv1_2', :method => 'post', :payload => data)
		rescue Exception => e
			response = nil
		end
		response = JSON.parse(response)
		return response
	end
end
