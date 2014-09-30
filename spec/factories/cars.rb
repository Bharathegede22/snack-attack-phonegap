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

# == Schema Information
#
# Table name: cars
#
#  id               :integer          not null, primary key
#  cargroup_id      :integer
#  location_id      :integer
#  name             :string(255)
#  status           :integer          default(0)
#  mileage          :integer          default(0)
#  vin              :string(255)
#  license          :string(255)
#  insurer          :string(255)
#  policy           :string(255)
#  wait_period      :integer
#  allindia         :boolean
#  color            :string(10)
#  leather_interior :boolean
#  mp3              :boolean
#  gps              :boolean
#  bluetooth        :boolean
#  radio            :boolean
#  dvd              :boolean
#  aux              :boolean
#  roofrack         :boolean
#  alloy_wheels     :boolean
#  handsfree        :boolean
#  child_seat       :boolean
#  smoking          :boolean
#  pet              :boolean
#  handicap         :boolean
#  jsi              :string(255)
#  jsi_old          :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#  starts           :date
#  ends             :date
#  kle_installed    :boolean          default(FALSE)
#  immobilizer      :boolean          default(FALSE)
#  tguid            :string(255)
#  km_reading       :string(11)
#  fuel_reading     :integer          default(0)
#
# Indexes
#
#  index_cars_on_cargroup_id  (cargroup_id)
#  index_cars_on_ends         (ends)
#  index_cars_on_location_id  (location_id)
#  index_cars_on_starts       (starts)
#
