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
