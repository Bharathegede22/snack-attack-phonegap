class Cargroup < ActiveRecord::Base
	
	has_many :bookings
	
  def cargroupObj
  	return Cargroup.where("status = 1").order("priority ASC")
  end  

  def locations
  	Rails.cache.fetch("cargroup-locations-#{self.id}") do
		 	Location.find_by_sql("SELECT l.* FROM locations l 
		 		INNER JOIN cars c ON c.location_id = l.id 
		 		WHERE c.cargroup_id = #{self.id} 
		 		GROUP BY l.id 
		 		ORDER BY l.id DESC")
		end
  end
  
  def self.list
  	Rails.cache.fetch("cargroup-list") do
  		Cargroup.find(:all, :conditions => "status = 1", :order => "priority ASC")
  	end
  end
	
	def self.name_list
		Rails.cache.fetch("cargroup-name-list") do
			Cargroup.find(:all, :select => "display_name", :conditions => "status = 1", :order => "priority ASC")
  	end
  end
  
	def self.return_group
  	Cargroup.all
  end
	
end
