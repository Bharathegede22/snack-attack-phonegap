# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sms  do
    booking {(FactoryGirl.create(:booking))}
    phone 1
    message "MyString"
    status 0
    error_message "MyString"
    #api_key "API KEY"
    sequence (:api_key) {|n| "API#{rand(100000)}"}
  end
end

# == Schema Information
#
# Table name: sms
#
#  id            :integer          not null, primary key
#  booking_id    :integer
#  phone         :string(10)
#  message       :text
#  status        :integer          default(0)
#  error_message :string(255)
#  api_key       :string(255)
#  delivered_on  :datetime
#  created_at    :datetime
#  updated_at    :datetime
#  activity      :string(255)
#
# Indexes
#
#  index_sms_on_api_key     (api_key)
#  index_sms_on_booking_id  (booking_id)
#  index_sms_on_created_at  (created_at)
#
