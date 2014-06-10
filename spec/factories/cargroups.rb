FactoryGirl.define do 
  factory :cargroup do
		sequence(:name) {|n| "cargroup#{rand(1000)}"}
		brand {FactoryGirl.create :brand}
		association :model
    
		sequence(:priority)
		seating 5
		wait_period 60
		daily_fare 2500
		hourly_fare 250
		weekly_fare 10000
		monthly_fare 40000
		hourly_km_limit 40
		daily_km_limit 250
		weekly_km_limit 1000
		monthly_km_limit 4000
		excess_kms 30
		fuel 1
		cartype 1
		drive 1
    status true
    
    factory :inactive_cargroup do
      status false
    end


    after :create do |cargroup, evaluator|
    	FactoryGirl.create(:car, cargroup_id: cargroup.id)
    end

  end 
end