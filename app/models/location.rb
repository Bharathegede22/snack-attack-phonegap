class Location < ActiveRecord::Base
	
	belongs_to :city
	
	def encoded_id
		CommonHelper.encode('location', self.id)
	end
	
	def h1(city=nil)
		return "Self Drive Cars In #{self.name}, #{self.city.name}"
	end
	
	def link(city=nil)
		return "http://www.zoomcar.in/" + CommonHelper.escape(self.city.name.downcase) + "/car-rental-in-" + CommonHelper.escape(self.name.downcase) + "_" + self.encoded_id
	end
	
	def live
		Rails.cache.fetch("location-cargroups-#{self.id}") do
			Cargroup.find_by_sql("SELECT cg.*, COUNT(DISTINCT c.id) AS total FROM cargroups cg 
				INNER JOIN cars c ON c.cargroup_id = cg.id 
				WHERE c.status > 0 AND c.location_id = #{self.id} 
				GROUP BY cg.id 
				ORDER BY cg.priority ASC")
		end
	end
	
	def mapcontent
		text = "<div style='width:240px;' class='size-12'><div class='zoom p-5 t-c'><b class='size-16'>" + self.shortname + "</b></div>"
		text << "<span style='color:red;'>" + self.disclaimer + "</span><br/>" if !self.disclaimer.blank?
		text << "<table width='100%' class='t-l'><tr class='size-14'><th>Car Type</th><th class='t-r'>Numbers</th></tr>"
		self.live.each do |cg|
			text << "<tr><td>" + cg.shortname + "</td><td class='t-r'>" + cg.total.to_s + "</td></tr>" if cg.total > 0
		end
		text << "</table></div>"
		return text.html_safe
	end
	
	def meta_description(city=nil)
		return "Self drive car hire in #{self.name.downcase}, #{self.city.name}. All-inclusive tariff covers fuel, insurance & taxes"
	end
	
	def meta_keywords(city=nil)
		@meta_keywords = "self drive car #{self.name.downcase} #{self.city.name.downcase}, self drive car rental, renting a car, self drive cars, zoomcar"
	end
	
	def meta_title(city=nil)
		return "Self Drive Car Rental In #{self.name}, #{self.city.name} | Zoomcar.in"
	end
	
	def shortname
		if self.status == 1
			return self.name.split(',').last
		else
			return self.name.split(',').last + " *"
		end
	end
	
	def self.live(city_id=1)
		Rails.cache.fetch("locations-#{city_id}") do
			Location.find_by_sql("SELECT l.* FROM locations l 
				INNER JOIN cars c ON c.location_id = l.id 
				WHERE c.status > 0 AND l.status > 0 AND l.city_id = #{city_id} 
				GROUP BY l.id
				ORDER BY id DESC")
		end
	end
	
end
