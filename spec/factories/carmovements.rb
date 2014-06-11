FactoryGirl.define do 
	factory :carmovement do

		association :cargroup
		association :location
		association :car
		active 1
		starts Time.today - 60.days
		ends Time.today + 90.days
	end 
end