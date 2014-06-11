FactoryGirl.define do 
  factory :booking do
		
  		association :user
      association :location
  		association :cargroup

      
      # Car is dependent on cargroup and location
      # Not adding this as cargroup is not mandatory
      # association :car
  		
			
			starts Time.today + 2.days
			ends Time.today + 3.days
      
      factory :live_booking do
        status 2
        starts Time.now - 17.hours
        ends Time.now + 1.day + 3.hours
      end
      
      factory :cancelled_booking do 
        status 10
      end
      
      factory :paid_booking do
        # There should be a payment reflecting the status of the payment
        # association :payment
        status 1
      end
      
      trait :hourly do
        starts Time.now + 1.day
        ends Time.now + 1.day + 1.hour
      end
      
      trait :daily do
        starts Time.now + 1.day
        ends Time.now + 2.days
      end
      
      trait :weekly do
        starts Time.now + 1.day
        ends Time.now + 1.days + 1.week
      end
      
      trait :monthly do
        starts Time.now + 1.day
        ends Time.now + 1.days + 28.days
      end
      
      
      after(:create) do |booking, evaluator|
        FactoryGirl.create(:car, cargroup_id:booking.cargroup_id,  location_id: booking.location_id)
      end
  end 
end
