FactoryGirl.define do 
	factory :carblock do
		association :car
		activity 1
		active 1
		starts Time.today
		ends Time.today + 2.days
	end 
end