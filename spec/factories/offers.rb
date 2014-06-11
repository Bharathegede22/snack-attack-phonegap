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
