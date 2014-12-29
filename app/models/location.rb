class Location < ActiveRecord::Base

	belongs_to :city
	belongs_to :hub, class_name: "Location"
	belongs_to :user
	belongs_to :zone
	
	has_many :images, :as => :imageable, dependent: :destroy
  acts_as_mappable


  def address_html
		text = ""
		text << self.name
		return text.html_safe
	end
	
	def encoded_id
		CommonHelper.encode('location', self.id)
  end

  def self.closest_city(lat,lng)
    Location.all.closest(:origin => [lat,lng])[0]
  end
	
	def h1(city=nil)
		if(self.seo_h1.present?)
			return self.seo_h1
		else
			return "Self Drive Cars at #{self.name}"
		end
	end
	
	def h2(city=nil)
		return "Zoom from <b>#{self.name}</b> or our <b>#{Location.live(self.city).length - 1}</b> other locations in #{self.city.name}"
	end
	
	def link(city=nil)
		return "http://" + HOSTNAME + "/" + CommonHelper.escape(self.city.link_name.downcase) + "/car-rental-in-" + CommonHelper.escape(self.name.downcase) + "_" + self.encoded_id
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
		if(self.seo_description.present?)
			return self.seo_description
		else
			return "Rent a car on self drive in #{self.city.name.downcase}. Pick up the car at #{self.name.downcase}"
		end
	end
	
	def meta_keywords(city=nil)
		if(self.seo_keywords.present?)
			self.seo_keywords
		else
			"self drive car #{self.name.downcase} #{self.city.name.downcase}, self drive car rental, renting a car, self drive cars, zoomcar"
		end
	end
	
	def meta_title(city=nil)
		if(self.seo_title.present?)
			return self.seo_title
		else
			return "Self Drive Cars On Rent At #{self.name}, #{self.city.name} | Zoomcar"
		end
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

# == Schema Information
#
# Table name: locations
#
#  id              :integer          not null, primary key
#  city_id         :integer
#  name            :string(255)
#  address         :string(255)
#  lat             :string(255)
#  lng             :string(255)
#  map_link        :string(255)
#  description     :text
#  mobile          :string(15)
#  email           :string(100)
#  status          :integer          default(1)
#  disclaimer      :string(255)
#  block_time      :integer
#  zone_id         :integer
#  hub_id          :integer
#  user_id         :integer
#  cash            :decimal(7, 2)    default(0.0)
#  seo_title       :string(255)
#  seo_description :string(255)
#  seo_keywords    :string(255)
#  seo_h1          :string(255)
#  seo_link        :string(255)
#  kle_enabled     :datetime
#
