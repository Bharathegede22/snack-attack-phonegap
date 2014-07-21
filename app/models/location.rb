class Location < ActiveRecord::Base
	
	belongs_to :city
	belongs_to :hub, class_name: "Location"
	belongs_to :user
	belongs_to :zone
	
	has_many :images, :as => :imageable, dependent: :destroy
	
	def address_html
		text = ""
		text << self.name
		return text.html_safe
	end
	
	def encoded_id
		CommonHelper.encode('location', self.id)
	end
	
	def h1(city=nil)
		return "Self Drive Cars at #{self.name}"
	end
	
	def h2(city=nil)
		return "Zoom from <b>#{self.name}</b> or our <b>#{Location.live(self.city).length - 1}</b> other locations in #{self.city.name}"
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
		text = "<div class='map-info'><div class='p-5 zoom size-16 f-b'>" + self.shortname + "</div>"
		text << "<div style='color:red;'>" + self.disclaimer + "</div>" if !self.disclaimer.blank?
		text << "<div class='p-5'><b>Car makes at site</b><br/>"
		self.live.each do |cg|
			text << cg.name + "<br/>" if cg.total > 0
		end
		text = text.chomp('<br/>') + "</div></div>"
		return text.html_safe
	end
	
	def meta_description(city=nil)
		return "Rent a car on self drive in #{self.city.name.downcase}. Pick up the car at #{self.name.downcase}"
	end
	
	def meta_keywords(city=nil)
		@meta_keywords = "self drive car #{self.name.downcase} #{self.city.name.downcase}, self drive car rental, renting a car, self drive cars, zoomcar"
	end
	
	def meta_title(city=nil)
		return "Self Drive Car Rent at #{self.name}, #{self.city.name} | Zoomcar.in"
		return "Self Drive Cars On Rent At #{self.name}, #{self.city.name} | Zoomcar"
	end
	
	def self.live(city)
		Rails.cache.fetch("locations-#{city.id}") do
			Location.find_by_sql("SELECT l.* FROM locations l 
				INNER JOIN cars c ON c.location_id = l.id 
				WHERE c.status > 0 AND l.status > 0 AND l.city_id = #{city.id} 
				GROUP BY l.id
				ORDER BY id DESC")
		end
	end
	
	def self.random(city)
  	Location.live(city).sample
  end
  
  def shortname(star=true)
		if self.status == 1
			return self.name.split(',').last.strip
		else
			if star
				return self.name.split(',').last.strip + " *"
			else
				return self.name.split(',').last.strip
			end
		end
	end
	
end
