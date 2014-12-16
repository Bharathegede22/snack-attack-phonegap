class UserUpdates
	attr_reader :ref_code, :current_user

	def initialize(current_user, cookies)
		@source = ""
		@ref_code = ""
		if cookies[:ref_code].present?
			ref_params = JSON.parse(cookies[:ref_code])
			@ref_code = ref_params["ref_code"].to_s
			@source = Referral::SOURCE.keys.include?(ref_params["source"].to_s) ? Referral::SOURCE[ref_params["source"].to_s] : Referral::SOURCE["others"]
		end
		@current_user = current_user
	end

	def apply_referral_code
		return unless valid_refcode?
		set_referral
		allot_credits
	end

	# Clear referral_cookies
	def clear_referral_cookie(cookies)
		cookies.delete(:ref_code, domain: ".#{HOSTNAME.gsub('www.','')}")
	end

	private

	# Checks to see if the ref_code is a valid one from a user
	def valid_refcode?
		ref_code.present? && referrer_user && referrer_user.ref_code.to_s == ref_code
	end

	# Finds the user who refferd the new user
	def referrer_user
		unless defined?(@referrer).present?
			@referrer = User.where(ref_code: ref_code).select("id,ref_code").first
		end
		@referrer
	end

	# creates the referral entry or updates it.
	def set_referral
		# update @referrer record in the reference table
		referral = Referral.where(referral_email: current_user.email, referral_user_id: referrer_user.id).first
		if referral.present?
			referral.update_attributes(source: source, signup_flag: 1)
		else
			Referral.create(referral_user_id: referrer_user.id, referral_email: current_user.email, source: @source, signup_flag: 1, referable_type: Referral::REFERABLE_TYPE[:signup])
		end
	end

	def allot_credits
		current_user.credits.create(amount: Credit::REFERRAL_CREDIT, action: true, status: true, source_name: Credit::SOURCE_NAME_INVERT["Sign up"])
	end

end