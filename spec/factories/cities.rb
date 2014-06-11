FactoryGirl.define do
  factory :city do
		sequence(:name) {|n| "city#{rand(100)}"}	
		lat "111"
		lng "101"
		description "description about the city"
		
		trait :bangalore do
			name "bangalore"
			lat "12.9667"
			lng "77.5667"
			description "Bangalore is the capital of Karnatka located on the deccan plateau"
		end
	
  end
end
