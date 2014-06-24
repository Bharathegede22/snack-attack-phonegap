class CityOffer < ActiveRecord::Base
	
	belongs_to :city
	belongs_to :offer
	
end
