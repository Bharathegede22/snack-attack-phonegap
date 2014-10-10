FactoryGirl.define do
  factory :attraction do
		sequence(:name) {|n| "Attraction#{rand(100)}"}	
		lat "111"
		lng "101"
		description "description about the the attration"
		best_time "Jan"
		city {FactoryGirl.create :city}
		places "some places"
  end
end

# == Schema Information
#
# Table name: attractions
#
#  id              :integer          not null, primary key
#  city_id         :integer
#  name            :string(255)
#  description     :text
#  places          :text
#  best_time       :text
#  lat             :string(255)
#  lng             :string(255)
#  state           :integer
#  category        :integer
#  outstation      :boolean
#  seo_title       :string(255)
#  seo_description :string(255)
#  seo_keywords    :string(255)
#  seo_h1          :string(255)
#  seo_link        :string(255)
#
# Indexes
#
#  index_attractions_on_city_id  (city_id)
#
