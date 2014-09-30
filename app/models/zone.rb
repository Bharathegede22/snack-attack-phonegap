class Zone < ActiveRecord::Base
	
	def self.live(city)
		Rails.cache.fetch("zones-#{city.id}") do
			Location.find_by_sql("SELECT z.* FROM zones z 
				INNER JOIN locations l ON l.zone_id = z.id 
				INNER JOIN cars c ON c.location_id = l.id 
				WHERE c.status > 0 AND l.status > 0 AND z.city_id = #{city.id} 
				GROUP BY z.id
				ORDER BY id DESC")
		end
	end
	
end

# == Schema Information
#
# Table name: zones
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  city_id         :integer
#  created_at      :datetime
#  updated_at      :datetime
#  seo_title       :string(255)
#  seo_description :string(255)
#  seo_keywords    :string(255)
#  seo_h1          :string(255)
#  seo_link        :string(255)
#
