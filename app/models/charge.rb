class Charge < ActiveRecord::Base
	
	belongs_to :booking
	
	def activity_text
		return self.activity.split('_').map{|x| x.capitalize}.join(' ')
	end
	
end
