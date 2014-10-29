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
		return "http://" + HOSTNAME + "/" + CommonHelper.escape(self.city.name.downcase) + "/car-rental-to-" + CommonHelper.escape(self.name.downcase) + "_" + self.encoded_id
	end
	
	def meta_description(city=nil)
		if(self.seo_description.present?)
			self.seo_description
		else
    	return "Rent a car on self drive from #{self.city.name} to #{self.name} by Zoomcar. "
    end
	end
	
	def meta_keywords(city=nil)
		if(self.seo_keywords.present?)
			self.seo_keywords
		else
			"self drive car #{self.name.downcase}, self drive car rental, renting a car, self drive cars, zoomcar"
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

# == Schema Information
#
# Table name: attractions
#
#  id              :integer          not null, primary key
#  city_id         :integer
#  name            :string(255)
#  description     :text
#  places          :text
#  best_time       :text
#  lat             :string(255)
#  lng             :string(255)
#  state           :integer
#  category        :integer
#  outstation      :boolean
#  seo_title       :string(255)
#  seo_description :string(255)
#  seo_keywords    :string(255)
#  seo_h1          :string(255)
#  seo_link        :string(255)
#
# Indexes
#
#  index_attractions_on_city_id  (city_id)
#
