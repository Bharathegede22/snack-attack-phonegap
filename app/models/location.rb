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
		Cargroup.find_by_sql("SELECT cg.*, COUNT(DISTINCT c.id) AS total FROM cargroups cg 
			INNER JOIN cars c ON c.cargroup_id = cg.id 
			WHERE c.status > 0 AND c.location_id = #{self.id} 
			GROUP BY cg.id 
			ORDER BY cg.priority ASC")
	end
	
	def mapcontent
		text = "<b>" + self.shortname + "</b><br/>"
		text << "<span style='color:red;'>" + self.disclaimer + "</span><br/>" if !self.disclaimer.blank?
		text << "<table width='100%'><tr><th>Car Type</th><th>Total</th></tr>"
		Cargroup.find_by_sql("SELECT cg.*, COUNT(DISTINCT c.id) AS total FROM cargroups cg 
			INNER JOIN cars c ON c.cargroup_id = cg.id 
			WHERE c.status > 0 AND c.location_id = #{self.id}
			GROUP BY cg.id 
			ORDER BY cg.priority ASC").each do |cg|
			text << "<tr><td>" + cg.shortname + "</td><td>" + cg.total.to_s + "</td></tr>" if cg.total > 0
		end
		text << "</table>"
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
		Location.find_by_sql("SELECT l.* FROM locations l 
			INNER JOIN cars c ON c.location_id = l.id 
			WHERE c.status > 0 AND l.status > 0 AND l.city_id = #{city_id} 
			GROUP BY l.id
			ORDER BY id DESC")
	end
	
end
