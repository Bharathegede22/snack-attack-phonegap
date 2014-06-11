FactoryGirl.define do 
	factory :model do
		sequence(:name) {|n| "model#{rand(1000)}"}
		association :brand
	end
end