FactoryGirl.define do
  factory :attraction do
		sequence(:name) {|n| "Attraction#{rand(100)}"}	
		lat "111"
		lng "101"
		description "description about the the attration"
		best_time "Jan"
		city {FactoryGirl.create :city}
		places "some places"
  end
end