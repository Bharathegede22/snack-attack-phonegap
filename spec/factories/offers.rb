# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :offer do
    heading "MyString"
    description "MyText"
    promo_code "TEST_PROMO"
    status "MyString"
    disclaimer "MyText"
    visibility "MyString"
    user_condition "MyText"
    booking_condition "MyText"
    output_condition "MyText"
		summary "Summary about the offer"
  end
end

# == Schema Information
#
# Table name: offers
#
#  id                           :integer          not null, primary key
#  heading                      :string(255)
#  description                  :text
#  promo_code                   :string(255)
#  status                       :boolean          default(TRUE)
#  disclaimer                   :text
#  visibility                   :integer          default(0)
#  user_condition               :text
#  booking_condition            :text
#  output_condition             :text
#  created_at                   :datetime
#  updated_at                   :datetime
#  summary                      :string(255)
#  instructions                 :text
#  valid_till                   :datetime
#  discount_type                :string(255)
#  value                        :integer
#  creation_starts              :datetime
#  creation_ends                :datetime
#  trip_start_date              :datetime
#  trip_end_date                :datetime
#  is_mobile_allowed            :boolean          default(FALSE)
#  is_web_allowed               :boolean          default(FALSE)
#  min_amount                   :integer
#  max_amount                   :integer
#  used_count                   :integer
#  ref_initial                  :string(255)
#  ref_immediate                :string(255)
#  booking_condition_return_nil :boolean          default(TRUE)
#  weekdays                     :string(255)
#
