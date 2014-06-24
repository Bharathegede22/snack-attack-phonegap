class Car < ActiveRecord::Base
	
	belongs_to :location

	def check_extension(city, starts, ends)
		check = 1
		Carmovement.find(:all, :conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, starts, starts, starts, ends]).each do |cm|
			start_time = (cm.starts > starts) ? cm.starts : starts
			end_time = (cm.ends < ends) ? cm.ends : ends
			if end_time == ends
				tmp = Inventory.check_plain(start_time, end_time, city, self.cargroup_id, cm.location_id, true, false, true)
			else
				tmp = Inventory.check_plain(start_time, end_time, city, self.cargroup_id, cm.location_id, true, false, false)
			end
			check = 0 if tmp[self.cargroup_id.to_s][cm.location_id.to_s] == 0
		end
		# Check Carblock
		if check == 1
			check = 0 if Carblock.count(:conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, starts, starts, starts, ends]) > 0
		end
		return check
	end
	
	def manage_inventory(city, starts, ends, block)
		Carmovement.find(:all, :conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, starts, starts, starts, ends]).each do |cm|
			start_time = (cm.starts > starts) ? cm.starts : starts
			end_time = (cm.ends < ends) ? cm.ends : ends
			if block
				# Block Inventory
				Inventory.block_plain(city, self.cargroup_id, cm.location_id, start_time, end_time)
			else
				# Release Inventory
				Inventory.release(city, self.cargroup_id, cm.location_id, start_time, end_time)
			end
		end
	end
	
end
