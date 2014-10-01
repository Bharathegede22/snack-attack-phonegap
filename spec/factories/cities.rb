FactoryGirl.define do
  factory :city do
		sequence(:name) {|n| "city#{rand(100)}"}	
		lat "111"
		lng "101"
		description "description about the city"
		
		trait :bangalore do
			name "bangalore"
			lat "12.9667"
			lng "77.5667"
			description "Bangalore is the capital of Karnatka located on the deccan plateau"
		end
	
  end
end

# == Schema Information
#
# Table name: cities
#
#  id                      :integer          not null, primary key
#  name                    :string(255)
#  description             :text
#  lat                     :string(255)
#  lng                     :string(255)
#  pricing_mode            :string(2)
#  contact_phone           :string(15)
#  contact_email           :string(50)
#  seo_title               :string(255)
#  seo_description         :string(255)
#  seo_keywords            :string(255)
#  seo_h1                  :string(255)
#  seo_inside_title        :string(255)
#  seo_inside_description  :string(255)
#  seo_inside_keywords     :string(255)
#  seo_inside_h1           :string(255)
#  seo_outside_title       :string(255)
#  seo_outside_description :string(255)
#  seo_outside_keywords    :string(255)
#  seo_outside_h1          :string(255)
#
