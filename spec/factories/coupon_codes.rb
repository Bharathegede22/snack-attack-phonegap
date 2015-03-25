# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :coupon_code do
  end
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
