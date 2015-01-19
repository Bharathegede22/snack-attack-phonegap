class Referral < ActiveRecord::Base
	belongs_to :user, :foreign_key => :referral_user_id

	REFERABLE_TYPE = {signup: 1}
	SOURCE = {"email" => 1, "fb" => 2, "twitter" => 3, "others" => 4}
	VALID = {alreay_used_email: 0, existing_license: 1, valid: 2}
	REFCODE = 'REFCODE'.freeze

	def self.validate_reference(user_email, user_id, field)
		return {:err => 'params missing'} if field[:field].blank?
		referral = Referral.where(referral_email: user_email, signup_flag: 1).first
		if referral
			# Validate if its a new user from unique license number
			users_with_same_license = User.where(field[:field] => field[:value])
			if (users_with_same_license.length > 1)
				valid = VALID[:existing_license]
			else
				valid = VALID[:valid]
			  Credit.create(user_id: user_id, amount: Credit::REFERRAL_CREDIT, action: true, status: true, source_name: Credit::SOURCE_NAME_INVERT["Sign up"])
			end
			referral.update_attributes(valid_referral: valid)
		end
	end

end