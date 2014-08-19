class City < ActiveRecord::Base
	
	has_many :attractions
	has_many :bookings
	has_many :city_offers
	has_many :locations
	has_many :offers, through: :city_offers
	
	def active_offers
		Rails.cache.fetch("offers-#{self.id}") do
			offers.where("status = 1 AND visibility = 1").to_a
		end
	end
	
	def h1(action=nil)
		return case action
		when 'attractions' then "Rent Self Drive Cars In & Around #{self.name}"
		when 'inside' then "Rent Self Drive Cars, Explore #{self.name}"
		when 'outside' then "Rent Self Drive Cars, Go Beyond #{self.name}"
		else "Self Drive Cars In #{self.name}"
		end
	end
	
	def link(action=nil)
		return "http://www.zoomcar.in/" + CommonHelper.escape(self.name.downcase) + case action
		when 'attractions' then "/attractions"
		when 'inside' then "/explore"
		when 'outside' then "/nearby"
		else ''
		end
	end
	
	def meta_description(action=nil) 
    return case action
    when 'attractions' then "Zoomcar Pick up points of your favourite cars on self drive rental in #{self.name}. Explore and beyond #{self.name} on your own drive"
    when 'inside' then "Find Self Drive Car Rental Locations In #{self.name} | Zoomcar"
    when 'outside' then "Self drive car rental for exploring around #{self.name}. All-inclusive tariff covers fuel, insurance & taxes"
    else "Book a self-drive car online for #{self.name.downcase} & around. Self driving car rental made easy like never before, simply join us for renting a car by the hour, day, week or month. Our tariff includes fuel, insurance & taxes."
    end
	end
	
	def meta_keywords(action=nil)
		return case action
		when 'attractions' then "zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
		when 'inside' then
			if(seo_inside_keywords.present?)
				seo_inside_keywords
			else
				"zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
			end
		when 'outside' then
			if(seo_outside_keywords.present?)
				seo_outside_keywords
			else
				"zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
			end
		else 
			if(seo_keywords.present?)
				seo_keywords
			else
				"zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
			end
		end
	end
	
	def meta_title(action=nil)
		return case action
		when 'attractions' then "Find Self Drive Car Rental Locations In #{self.name} | Zoomcar"
		when 'inside' then 
			if(self.seo_inside_title.present?)
				seo_inside_title
			else
				"Self Drive Car Rental, Explore #{self.name} | Zoomcar.in"
			end
		when 'outside' then 
			if(self.seo_outside_title.present?)
				seo_outside_title
			else
				"Self Drive Car Rental, Explore Beyond #{self.name} | Zoomcar.in"
			end
		else
			if(self.seo_title.present?)
				seo_title
			else
				"Self Drive Cars Rental In #{self.name} | Join Online, Book A Car & Drive | Zoomcar.in"
			end
		end
	end
	
	def mode
		return "Pricing#{self.pricing_mode}".constantize
	end
	
	def self.active
		Rails.cache.fetch("cities") do
			City.find_by_sql("SELECT * FROM cities")
		end
	end
	
	def self.active_hash
		tmp = {}
		active.each do |c|
			tmp[c.name.downcase] = c
		end
		return tmp
	end
	
	def self.lookup(name)
		return active_hash[name.downcase]
	end
	
end
