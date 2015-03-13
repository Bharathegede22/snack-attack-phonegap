class Referral < ActiveRecord::Base
	belongs_to :user, :foreign_key => :referral_user_id

	REFERABLE_TYPE = {signup: 1}
	SOURCE = {"email" => 1, "fb" => 2, "twitter" => 3, "others" => 4}
	VALID = {alreay_used_email: 0, existing_license: 1, valid: 2, existing_phone: 3}
	REFCODE = 'REFCODE'.freeze

	def self.validate_reference(user)
		referral = Referral.where(referral_email: user.email, signup_flag: 1).first
		if referral && user.phone_verified
			# give credits unless already given
			unless user.sign_up_credits_earned?
				Credit.create(user_id: user.id, amount: Credit::REFERRAL_CREDIT, action: true, status: true, source_name: Credit::SOURCE_NAME_INVERT["Sign up"])
			end
			referral.update_attributes(valid_referral: VALID[:valid])
		end
	end

end