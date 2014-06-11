# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :t4u_log do
    association :car
    status "MyString"
    message "MyText"
    notice "MyText"
    action "MyString"
  end
end
