class Cargroup < ActiveRecord::Base
	
	has_many :bookings
	belongs_to :brand
	belongs_to :model
	
  def active_pricing(city)
		Rails.cache.fetch("cargroup-pricing-#{city}") do
			Pricing.find_by_sql("SELECT * FROM pricings 
				WHERE city_id = #{city} AND cargroup_id = #{self.id} AND status = 1 AND starts >= '#{Time.today.to_s(:db)}' 
				ORDER BY starts DESC
			")
		end
	end
	
	def cargroupObj
  	return Cargroup.where("status = 1").order("priority ASC")
  end  
	
	def encoded_id
		CommonHelper.encode('cargroup', self.id)
	end
	
	def h1(city)
		return "Hire #{self.name}"
	end
	
	def link(city)
		return "http://www.zoomcar.in/" + CommonHelper.escape(city.name.downcase) + "/" + CommonHelper.escape(self.name.downcase) + "-car-rental_" + self.encoded_id
	end
	
	def locations
  	Rails.cache.fetch("cargroup-locations-#{self.id}") do
		 	Location.find_by_sql("SELECT l.* FROM locations l 
		 		INNER JOIN cars c ON c.location_id = l.id 
		 		WHERE c.cargroup_id = #{self.id} AND c.status > 0 AND l.status > 0 
		 		GROUP BY l.id 
		 		ORDER BY l.id DESC")
		end
  end
  
  def locations_hash
  	tmp = {}
  	self.locations.each do |l|
  		tmp[l.id.to_s] = 1
  	end
  	return tmp
  end
  
  def meta_description(city)
		return "Self drive #{self.name.downcase} car on hire by the hour, daily, weekly and monthly basis at affordable price in #{city.name}"
	end
	
	def meta_keywords(city)
		@meta_keywords = "self drive car #{self.name.downcase} #{city.name.downcase}, zoomcar"
	end
	
	def meta_title(city)
		return "#{self.name} Car On Self Drive In #{city.name} | Zoomcar"
	end
	
	def self.list
  	Rails.cache.fetch("cargroup-list") do
  		Cargroup.find_by_sql("SELECT * FROM cargroups WHERE status = 1 ORDER BY priority ASC")
  	end
  end
	
	def self.city_list(city)
  		Rails.cache.fetch("cargroup-#{city.name}-list") do
  			city.locations.collect(&:live).flatten.uniq
  		end
  	end

  def self.live(city_id=1)
		Cargroup.find_by_sql("SELECT cg.*, l.name AS l_name, l.id AS l_id, COUNT(DISTINCT c.id) AS total FROM cargroups cg 
			INNER JOIN cars c ON c.cargroup_id = cg.id 
			INNER JOIN locations l ON l.id = c.location_id 
			WHERE cg.status > 0 AND c.status > 0 AND l.status > 0 AND l.city_id = #{city_id} 
			GROUP BY cg.id, l.id 
			ORDER BY cg.priority ASC")
	end
	
	def self.name_list
		Rails.cache.fetch("cargroup-name-list") do
			Cargroup.find(:all, :select => "display_name", :conditions => "status = 1", :order => "priority ASC")
  	end
  end
  
  def self.random
  	Cargroup.where("status > 0").order("RAND()").first
  end
  
	def self.return_group
  	Cargroup.all
  end
	
	def shortname
		self.display_name.gsub('Mahindra ','') rescue ""
	end
	
end
