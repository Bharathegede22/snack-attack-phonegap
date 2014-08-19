class Attraction < ActiveRecord::Base
	
	belongs_to :city
	
	def encoded_id
		CommonHelper.encode('attraction', self.id)
	end
	
	def h1(city=nil)
		if(self.seo_h1.present?)
			return self.seo_h1
		else
			return "Self Drive Car From #{self.city.name} to #{self.name} "
		end
	end
	
	def link(city=nil)
		return "http://www.zoomcar.in/" + CommonHelper.escape(self.city.name.downcase) + "/car-rental-to-" + CommonHelper.escape(self.name.downcase) + "_" + self.encoded_id
	end
	
	def meta_description(city=nil)
    return "Rent a car on self drive from #{self.city.name} to #{self.name} by Zoomcar. "
	end
	
	def meta_keywords(city=nil)
		if(self.seo_keywords.present?)
			@meta_keywords = self.seo_keywords
		else
			@meta_keywords = "self drive car #{self.name.downcase}, self drive car rental, renting a car, self drive cars, zoomcar"
		end
	end
	
	def meta_title(city=nil)
		if(self.seo_title.present?)
			return self.seo_title
		else
    	return "Self Drive Cars On Rent From #{self.city.name} To #{self.name} | Zoomcar"
    end
	end
	
end
