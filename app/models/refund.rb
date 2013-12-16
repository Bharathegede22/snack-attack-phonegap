class Refund < ActiveRecord::Base
	
	belongs_to :booking
	
	def through_text
		return self.through.split('_').map{|y| y.capitalize}.join(' ')
	end
	
end
