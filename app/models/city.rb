class City < ActiveRecord::Base
	
	has_many :attractions
	has_many :locations
	def h1(action=nil)
		return case action
		when 'inside' then "Rent Self Drive Cars, Explore #{self.name}"
		when 'outside' then "Rent Self Drive Cars, Go Beyond #{self.name}"
		else "Rent Self Drive Cars In & Around #{self.name}"
		end
		return 
	end
	
	def link(action=nil)
		return "http://www.zoomcar.in/" + CommonHelper.escape(self.name.downcase) + case action
		when 'inside' then "/explore"
		when 'outside' then "/nearby"
		else ''
		end
	end
	
	def meta_description(action=nil) 
    return case action
    when 'inside' then "Find Self Drive Car Hire Locations In #{self.name} | Zoomcar"
    when 'outside' then "Self drive car hire for exploring around #{self.name}. All-inclusive tariff covers fuel, insurance & taxes"
    
    else "Zoomcar Pick up points of your favourite cars on self drive rental in #{self.name}. Explore and beyond #{self.name} on your own drive"
    end
	end
	
	def meta_keywords(action=nil)
		return case action
		when 'inside' then "zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
		when 'outside' then "zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
		else "zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
		end
	end
	
	def meta_title(action=nil)
		return case action
		when 'inside' then "Self Drive Car Rental, Explore #{self.name} | Zoomcar.in"
		when 'outside' then "Self Drive Car Rental, Explore Beyond #{self.name} | Zoomcar.in"
		else "Find Self Drive Car Hire Locations In #{self.name} | Zoomcar"
		end
	end
	
end
