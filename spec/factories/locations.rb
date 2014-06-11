FactoryGirl.define do
  factory :location do
		sequence(:name) {|n| "location#{n*rand(1000)}"}
		association :city
		address "Location address"
		lat "12.3393"
		lng "77.3994"
		map_link "http://maps.google.com"
		description "Description about the location "
    sequence(:email) {|n| "#{name}@zoomcartest.com"}
  end
end
