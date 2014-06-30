class Pricing < ActiveRecord::Base
	
	belongs_to :cargroup
	belongs_to :city
	
	has_many :bookings
	
	def mode
		return "Pricing#{self.version}".constantize
	end
	
end
