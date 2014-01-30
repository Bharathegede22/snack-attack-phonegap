class City < ActiveRecord::Base
	
	has_many :attractions
	
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
		when 'inside' then "Self drive car hire for exploring #{self.name}. All-inclusive tariff covers fuel, insurance & taxes"
		when 'outside' then "Self drive car hire for exploring around #{self.name}. All-inclusive tariff covers fuel, insurance & taxes"
		else "Self drive cars in #{self.name}. All-inclusive tariff covers fuel, insurance & taxes"
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
		else "Self Drive Car Rental, Explore #{self.name} & Beyond | Zoomcar.in"
		end
	end
	
end
