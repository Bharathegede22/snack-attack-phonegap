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

	def referral_message
		simple_format "Hi

Your friend <a href='www.google.com'>awesome</a> wants to share the joy, adventure, and independence of self-drive car rental with you!".html_safe
	end
end
