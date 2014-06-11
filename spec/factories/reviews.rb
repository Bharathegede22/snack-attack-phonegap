FactoryGirl.define do 
  factory :review do
		association :user
		comment "comments in the review"
		sequence(:jsi) {|n| "#{rand(1000)}"}
  end 
end