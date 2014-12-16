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
		else "Self-Drive Cars In #{self.name}"
		end
	end
	
	def inactive?
		!self.active || self.prelaunch
	end
	
	def link(action=nil)
		return "http://" + HOSTNAME + "/" + CommonHelper.escape(self.link_name.downcase) + case action
		when 'attractions' then "/attractions"
		when 'inside' then "/explore"
		when 'outside' then "/nearby"
		else ''
		end
	end
	
	def meta_description(action=nil) 
    return case action
    when 'attractions' then "Zoomcar Pick up points of your favourite cars on self drive rental in #{self.name}. Explore and beyond #{self.name} on your own drive"
    when 'inside' then 
    	if(self.seo_inside_description.present?)
				self.seo_inside_description
			else
				"Find Self Drive Car Rental Locations In #{self.name} | Zoomcar"
			end
    when 'outside' then 
    	if(self.seo_outside_description.present?)
				self.seo_outside_description
			else
				"Self drive car rental for exploring around #{self.name}. All-inclusive tariff covers fuel, insurance & taxes"
			end
    else 
    	if(self.seo_description.present?)
				self.seo_description
			else
				"Book a self-drive car online for #{self.name.downcase} & around. Self driving car rental made easy like never before, simply join us for renting a car by the hour, day, week or month. Our tariff includes fuel, insurance & taxes."
			end
    end
	end
	
	def meta_keywords(action=nil)
		return case action
		when 'attractions' then "zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
		when 'inside' then
			if(seo_inside_keywords.present?)
				self.seo_inside_keywords
			else
				"zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
			end
		when 'outside' then
			if(seo_outside_keywords.present?)
				self.seo_outside_keywords
			else
				"zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
			end
		else 
			if(seo_keywords.present?)
				self.seo_keywords
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
				self.seo_inside_title
			else
				"Self Drive Car Rental, Explore #{self.name} | Zoomcar"
			end
		when 'outside' then 
			if(self.seo_outside_title.present?)
				self.seo_outside_title
			else
				"Self Drive Car Rental, Explore Beyond #{self.name} | Zoomcar"
			end
		else
			if(self.seo_title.present?)
				self.seo_title
			else
				"Self Drive Cars Rental In #{self.name} | Join Online, Book A Car & Drive | Zoomcar"
			end
		end
	end
	
	def mode
		return "Pricing#{self.pricing_mode}".constantize
	end
	
	def self.active
		Rails.cache.fetch("cities-active") do
			City.where(:active => 1).all
		end
	end
	
	def self.active_hash
		tmp = {}
		active.each do |c|
			tmp[c.name.downcase] = c
		end
		return tmp
	end
	
	def self.h1
		"Self Drive Cars In India"
	end
	
	def self.getall
		Rails.cache.fetch("cities-all") do
			City.all.to_a
		end
	end
	
	def self.getall_hash
		tmp = {}
		getall.each do |c|
			tmp[c.link_name.downcase] = c
		end
		return tmp
	end

	def self.link
		"http://#{HOSTNAME}"
	end
	
	def self.lookup(name)
		return active_hash[name.downcase]
	end
	
	def self.lookup_all(name)
		return getall_hash[name.downcase]
	end

	def self.meta_description
		"Book a self-drive car online in India. Self driving car rental made easy like never before, simply join us for renting a car by the hour, day, week or month. Our tariff includes fuel, insurance & taxes."
	end
	
	def self.meta_keywords
		"zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
	end
	
	def self.meta_title
		"Self Drive Cars Rental In India | Join Online, Book A Car & Drive | Zoomcar"
	end
	
end

# == Schema Information
#
# Table name: cities
#
#  id                      :integer          not null, primary key
#  name                    :string(255)
#  description             :text
#  lat                     :string(255)
#  lng                     :string(255)
#  pricing_mode            :string(2)
#  contact_phone           :string(15)
#  contact_email           :string(50)
#  seo_title               :string(255)
#  seo_description         :string(255)
#  seo_keywords            :string(255)
#  seo_h1                  :string(255)
#  seo_inside_title        :string(255)
#  seo_inside_description  :string(255)
#  seo_inside_keywords     :string(255)
#  seo_inside_h1           :string(255)
#  seo_outside_title       :string(255)
#  seo_outside_description :string(255)
#  seo_outside_keywords    :string(255)
#  seo_outside_h1          :string(255)
#  active                  :boolean          default(FALSE)
#  promo_pricing           :boolean          default(FALSE)
#  prelaunch               :boolean          default(FALSE)
#  link_name               :string(255)
#  address                 :text
#  directions              :text
#
