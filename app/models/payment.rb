class Payment < ActiveRecord::Base
	
	belongs_to :booking
	
	def through_text
		return self.through.capitalize
	end
	
end
