module SmsTask
	class << self
		def message_exotel(number,msg,id)
			if Rails.env.production?
				Exotel.send_message(number,msg,id)
			else
				Exotel.send_message(CommonHelper::INTERCEPTOR_NUMBER,msg,id)
			end
		end
		def message_sidekiq(number,msg,id)
			if Rails.env.production?
				SmsSender.perform_async(number,msg,id)
			else
				SmsSender.perform_async(CommonHelper::INTERCEPTOR_NUMBER,msg,id)
			end
		end
	end  
end