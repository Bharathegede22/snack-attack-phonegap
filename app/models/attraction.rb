class Attraction < ActiveRecord::Base
	
	belongs_to :city
	
	def encoded_id
		CommonHelper.encode('attraction', self.id)
	end
	
	def h1(city=nil)
		return "Self Drive Car From #{self.city.name} to #{self.name} "
	end
	
	def link(city=nil)
		return "http://www.zoomcar.in/" + CommonHelper.escape(self.city.name) + "/car-rental-to-" + CommonHelper.escape(self.name.downcase) + "_" + self.encoded_id
	end
	
	def meta_description(city=nil)
    return "Rent a car on self drive from #{self.city.name} to #{self.name} by Zoomcar. "
	end
	
	def meta_keywords(city=nil)
		@meta_keywords = "self drive car #{self.name.downcase}, self drive car rental, renting a car, self drive cars, zoomcar"
	end
	
	def meta_title(city=nil)
    return "Self Drive Cars On Rent From #{self.city.name} To #{self.name} | Zoomcar"
	end
	
end
