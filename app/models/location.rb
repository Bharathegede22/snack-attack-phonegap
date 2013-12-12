class Location < ActiveRecord::Base
	
	def shortname
		return self.name.split(',').last
	end
	
	def self.live
		Location.find(:all, :order => "id DESC")
	end
	
end
