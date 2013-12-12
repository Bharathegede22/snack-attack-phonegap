class Attraction < ActiveRecord::Base
	
	belongs_to :city
	
	def encoded_id
		CommonHelper.encode('attraction', self.id)
	end
	
	def h1
		return "Rent Self Drive Cars from #{self.city.name} To " + self.name
	end
	
	def link
		return "http://www.zoomcar.in/" + CommonHelper.escape(self.city.name.downcase) + "/car-rental-to-" + CommonHelper.escape(self.name.downcase) + "_" + self.encoded_id
	end
	
	def meta_description
		return "Self-drive car hire from #{self.city.name} to #{self.name}. All-inclusive tariff covers fuel, insurance & taxes"
	end
	
	def meta_keywords
		@meta_keywords = "self drive car #{self.name.downcase}, self drive car rental, renting a car, self drive cars, zoomcar"
	end
	
	def meta_title
		return "Self Drive Car Rental from #{self.city.name} To " + self.name + " | Zoomcar.in"
	end
	
end
