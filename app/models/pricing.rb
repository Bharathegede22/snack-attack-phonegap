class Pricing < ActiveRecord::Base
	
	belongs_to :cargroup
	belongs_to :city
	
	has_many :bookings
	
	def hourly_discounted
		if self.hourly_discounted_fare.blank?
			return (self.hourly_fare*(100 - self.mode::WEEKDAY_DISCOUNT)/100.0).to_i
		else
			return self.hourly_discounted_fare
		end
	end
	
	def daily_discounted
		if self.daily_discounted_fare.blank?
			return (self.daily_fare*(100 - self.mode::WEEKDAY_DISCOUNT)/100.0).to_i
		else
			return self.daily_discounted_fare
		end
	end
	
	def mode
		return "Pricing#{self.version}".constantize
	end
	
end
