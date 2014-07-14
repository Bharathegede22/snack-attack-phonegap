class Cargroup < ActiveRecord::Base
	
	has_many :bookings
	
	def active_pricing(city)
		Rails.cache.fetch("cargroup-pricing-#{city}-#{self.id}") do 
			city = City.find(city)
			Pricing.find_by_sql("SELECT * FROM pricings 
				WHERE city_id = #{city.id} AND 
				cargroup_id = #{self.id} AND 
				status = 1 AND 
				starts <= '#{Time.today.to_s(:db)}' AND 
				version = '#{city.pricing_mode}' 
				ORDER BY starts DESC 
				LIMIT 1
			")[0]
		end
	end
	
	def encoded_id
		CommonHelper.encode('cargroup', self.id)
	end
	
	def h1(city)
		return "Rent #{self.name}"
	end
	
	def link(city)
		return "http://www.zoomcar.in/" + CommonHelper.escape(city.name.downcase) + "/" + CommonHelper.escape(self.name.downcase) + "-car-rental_" + self.encoded_id
	end
	
	def locations(city)
  	Rails.cache.fetch("cargroup-locations-#{city.id}-#{self.id}") do
		 	Location.find_by_sql("SELECT l.* FROM locations l 
		 		INNER JOIN cars c ON c.location_id = l.id 
		 		WHERE c.cargroup_id = #{self.id} AND c.status > 0 AND l.status > 0 AND l.city_id = #{city.id} 
		 		GROUP BY l.id 
		 		ORDER BY l.id DESC")
		end
  end
  
  def locations_hash(city)
  	tmp = {}
  	self.locations(city).each do |l|
  		tmp[l.id.to_s] = 1
  	end
  	return tmp
  end
  
  def meta_description(city)
		return "Self drive #{self.name.downcase} car on rent by the hour, daily, weekly and monthly basis at affordable price in #{city.name}"
	end
	
	def meta_keywords(city)
		@meta_keywords = "self drive car #{self.name.downcase} #{city.name.downcase}, zoomcar"
	end
	
	def meta_title(city)
		return "#{self.name} Car On Self Drive In #{city.name} | Zoomcar"
	end
	
	def self.list(city)
  	Rails.cache.fetch("cargroup-list-#{city.id}") do
  		Cargroup.find_by_sql("SELECT cg.* FROM cargroups cg 
				INNER JOIN cars c ON c.cargroup_id = cg.id 
				INNER JOIN locations l ON l.id = c.location_id 
				WHERE cg.status > 0 AND c.status > 0 AND l.status > 0 AND l.city_id = #{city.id} 
				GROUP BY cg.id
				ORDER BY cg.priority ASC
			")
  	end
  end
	
	def self.live(city)
		Cargroup.find_by_sql("SELECT cg.*, l.name AS l_name, l.id AS l_id, COUNT(DISTINCT c.id) AS total FROM cargroups cg 
			INNER JOIN cars c ON c.cargroup_id = cg.id 
			INNER JOIN locations l ON l.id = c.location_id 
			WHERE cg.status > 0 AND c.status > 0 AND l.status > 0 AND l.city_id = #{city.id} 
			GROUP BY cg.id, l.id 
			ORDER BY cg.priority ASC")
	end
	
  def self.random(city)
  	Cargroup.list(city).sample
  end
  
	def shortname
		self.display_name.gsub('Mahindra ','') rescue ""
	end
	
end
