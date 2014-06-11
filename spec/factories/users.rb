FactoryGirl.define do 
  factory :user do
    sequence(:email) {|n| "user#{n}#{rand(10000)}@example.com" }
    sequence(:name) {|n| "user#{n}#{rand(1000)}" }
    password  "testing123"
		created_at 2.day.ago.to_s(:db)
		updated_at 1.day.ago.to_s(:db)
    
    factory :blacklisted_user do 
      status CommonHelper::BLACKLISTED_STATUS
      blacklist_reason "Driving the car over 150 km/hr"
      blacklist_auth "Greg"
    end
    
    trait :mobile do
      phone "95914 33333"
    end
  end
  
  
end