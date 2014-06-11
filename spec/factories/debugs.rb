# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :debug do
    debugable_id 1
    debugable_type "MyString"
    description "MyText"
  end
end
