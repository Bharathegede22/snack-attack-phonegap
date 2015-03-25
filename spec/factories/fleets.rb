FactoryGirl.define do
  factory :fleet do
		sequence(:name) {|n| "Fleet#{n*rand(100)}"}	
		sequence(:mobile) {|n| "12345678#{rand(100)}"}
		role "1"
		location {FactoryGirl.create :location}
		
  end
end