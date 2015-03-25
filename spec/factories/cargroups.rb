FactoryGirl.define do 
  factory :cargroup do
		sequence(:name) {|n| "cargroup#{rand(1000)}"}
		# brand {FactoryGirl.create :brand}
		# association :model
		# association :brand
    
		sequence(:priority)
		seating 5
		wait_period 60
		# daily_fare 2500
		# hourly_fare 250
		# weekly_fare 10000
		# monthly_fare 40000
		# hourly_km_limit 40
		# daily_km_limit 250
		# weekly_km_limit 1000
		# monthly_km_limit 4000
		# excess_kms 30
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

# == Schema Information
#
# Table name: cargroups
#
#  id               :integer          not null, primary key
#  brand_id         :integer
#  model_id         :integer
#  name             :string(255)
#  display_name     :string(255)
#  status           :boolean          default(FALSE)
#  ended            :boolean          default(FALSE)
#  priority         :integer
#  seating          :integer
#  wait_period      :integer
#  disclaimer       :string(255)
#  description      :text
#  cartype          :integer
#  drive            :integer
#  fuel             :integer
#  manual           :boolean
#  color            :string(10)
#  power_windows    :boolean
#  aux              :boolean
#  leather_interior :boolean
#  power_seat       :boolean
#  bluetooth        :boolean
#  gps              :boolean
#  premium_sound    :boolean
#  radio            :boolean
#  sunroof          :boolean
#  power_steering   :boolean
#  dvd              :boolean
#  ac               :boolean
#  heating          :boolean
#  cd               :boolean
#  mp3              :boolean
#  alloy_wheels     :boolean
#  handsfree        :boolean
#  cruise           :boolean
#  smoking          :boolean
#  pet              :boolean
#  handicap         :boolean
#  kmpl             :float
#  seo_title        :string(255)
#  seo_description  :string(255)
#  seo_keywords     :string(255)
#  seo_h1           :string(255)
#  seo_link         :string(255)
#  kle              :boolean          default(FALSE)
#
