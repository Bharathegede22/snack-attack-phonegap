class Charge < ActiveRecord::Base
	
	belongs_to :booking
	
	default_scope where("(active = 1)")
	
	def activity_text
		return self.activity.split('_').map{|x| x.capitalize}.join(' ')
	end
	
end
