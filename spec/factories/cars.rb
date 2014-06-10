FactoryGirl.define do 
	factory :car do

		association :cargroup
		association :location

		sequence (:name) {|n| "Car#{n*rand(100000)}"}
		starts 3.months.ago.to_s(:db)
		sequence(:license) {|n| "KA#{rand(100)}MA#{rand(1000)}"}
    
    trait :kle_installed do
      kle_installed true
    end
    
    after(:create) do |car, evaluator|
      # car.location_id = evaluator.location_id if evaluator.location_id 
      FactoryGirl.create(:carmovement, car_id: car.id, location_id: car.location_id, cargroup_id: car.cargroup_id)
    end
	end 
end