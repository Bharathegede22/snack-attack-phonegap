# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :fuel_cost do
    cost "9.99"
    status false
    fuel_type 1
  end
end
