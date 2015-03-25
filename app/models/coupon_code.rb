class CouponCode < ActiveRecord::Base
	
	belongs_to :booking
	belongs_to :offer
	 
end

# == Schema Information
#
# Table name: coupon_codes
#
#  id         :integer          not null, primary key
#  code       :string(255)
#  used       :boolean          default(FALSE)
#  booking_id :integer
#  offer_id   :integer          not null
#  used_at    :datetime
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_coupon_codes_on_code  (code)
#
