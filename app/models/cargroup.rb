class Cargroup < ActiveRecord::Base
	
	has_many :bookings
	
  def cargroupObj
  	return Cargroup.where("status = 1").order("priority ASC")
  end  
	
	def check_fare(start_date, end_date)
		temp = {:estimate => 0, :discount => 0, :days => 0, :normal_days => 0, :discounted_days => 0, :hours => 0, :normal_hours => 0, :discounted_hours => 0}
		cargroup = self
		rate = [cargroup.hourly_fare, cargroup.daily_fare]
		h = (end_date.to_i - start_date.to_i)/3600
		h += 1 if (end_date.to_i - start_date.to_i) > h*3600
		d = h/24
		h = h - d*24
		temp[:days] = d
		temp[:hours] = h
		
		# Daily Fair
		if d > 0
			(0..(d-1)).each do |i|
				wday = (start_date + i.days).wday
				temp[:estimate] += rate[1]
				if wday > 0 && wday < 5
					temp[:discount] += rate[1]*0.35
					temp[:discounted_days] += 1
				else
					temp[:normal_days] += 1
				end
			end
		end
		# Hourly Fair
		wday = (start_date + d.days).wday
		if h <= 10
			tmp = rate[0]*h
		else
			tmp = rate[1]
		end
		temp[:estimate] += tmp
		if wday > 0 && wday < 5
			temp[:discount] += tmp*0.35
			temp[:discounted_hours] += h
		else
			temp[:normal_hours] += h
		end
		temp[:estimate] = temp[:estimate].round
		temp[:discount] = temp[:discount].round
		return temp
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
	
	def shortname
		return self.display_name.gsub('Mahindra ','')
	end
	
end
