# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :email do
  	user {(FactoryGirl.create(:user))}
  	activity "Activity"
  end
end
