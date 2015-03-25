module UsersHelper

	def referral_credits_earned
		return 0 if current_user.blank?
		unless defined? @referral_credits 
			@referral_credits = current_user.credits.where(source_name: Credit::SOURCE_NAME_INVERT['Referral'], status: true, action: 1).collect(&:amount).sum.to_i
		end
		@referral_credits
	end

	def signup_credits_earned?
		return flase if current_user.blank?
		current_user.credits.where(source_name: Credit::SOURCE_NAME_INVERT['Sign up']).limit(1).present?
	end

	# Makes API call to send otp sms
	#
	# Author:: Rohit
  # Date:: 13/03/2015
  #
  def call_send_otp_sms_api
    args = { platform: "web", auth_token: current_user.generate_authentication_token}
    url = "#{ADMIN_HOSTNAME}/mobile/v3/user_activities/send_otp_sms"
    response = ApiModule.admin_api_post_call(url, args)
  end

	# Makes API call to verify user's otp
	#
	# Author:: Rohit
  # Date:: 13/03/2015
  #
  def call_verify_otp_sms_api
    args = { platform: "web", auth_token: current_user.generate_authentication_token, otp_code: params[:otp_code]}
    url = "#{ADMIN_HOSTNAME}/mobile/v3/user_activities/verify_opt_sms"
    response = ApiModule.admin_api_post_call(url, args)
  end

end
