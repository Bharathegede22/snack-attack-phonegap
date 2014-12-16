class Referral < ActiveRecord::Base
	belongs_to :user, :foreign_key => :referral_user_id

	REFERABLE_TYPE = {signup: 1}
	SOURCE = {"email" => 1, "fb" => 2, "twitter" => 3, "others" => 4}
	VALID = {alreay_used_email: 0, existing_license: 1, valid: 2}
	REFCODE = 'REFCODE'.freeze

end