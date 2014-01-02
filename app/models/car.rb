class Car < ActiveRecord::Base
	
	def self.active
		Car.count(:conditions => "status = 1")
	end
	
end
