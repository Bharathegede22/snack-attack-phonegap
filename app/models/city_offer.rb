class CityOffer < ActiveRecord::Base
	
	belongs_to :city
	belongs_to :offer
	
end

# == Schema Information
#
# Table name: city_offers
#
#  id         :integer          not null, primary key
#  offer_id   :integer
#  city_id    :integer
#  created_at :datetime
#  updated_at :datetime
#
