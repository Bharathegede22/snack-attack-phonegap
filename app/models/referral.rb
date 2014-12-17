class Referral < ActiveRecord::Base
	belongs_to :user, :foreign_key => :referral_user_id

	REFERABLE_TYPE = {signup: 1}
	SOURCE = {"email" => 1, "fb" => 2, "twitter" => 3, "others" => 4}
	VALID = {alreay_used_email: 0, existing_license: 1, valid: 2}
	REFCODE = 'REFCODE'.freeze

	def self.validate_reference(user_email, field)
		return {:err => 'params missing'} if field[:field].blank?
		referral = Referral.where(referral_email: user_email, signup_flag: 1).first
		if referral
			# Validate if its a new user from unique license number
			users_with_same_license = User.where(field[:field] => field[:value])
			valid = (users_with_same_license.length > 1) ? VALID[:existing_license] : valid = VALID[:valid]
			referral.update_attributes(valid_referral: valid)
		end
	end

end