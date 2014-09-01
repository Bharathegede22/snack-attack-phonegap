class Car < ActiveRecord::Base
	
	belongs_to :cargroup
	belongs_to :location
	
	def check_inventory(city, starts_was, ends_was, starts, ends)
		check = 1
		cargroup = self.cargroup
		
		# Check Carblock
		if starts != starts_was || ends != ends_was
			if starts > ends_was + cargroup.wait_period.minutes || ends < starts_was - cargroup.wait_period.minutes
				# Non Overlapping Reschedule
				start_time = (starts - cargroup.wait_period.minutes)
				end_time = (ends + cargroup.wait_period.minutes)
				check = 0 if Carblock.count(:conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, start_time, start_time, start_time, end_time]) > 0
			else
				# Overlapping Reschedule
				if starts < starts_was
					start_time = (starts - cargroup.wait_period.minutes)
					check = 0 if Carblock.count(:conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, start_time, start_time, start_time, starts_was]) > 0
				end
				if check == 1 && ends > ends_was
					end_time = (ends + cargroup.wait_period.minutes)
					check = 0 if Carblock.count(:conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, ends_was, ends_was, ends_was, end_time]) > 0
				end
			end
		else
			start_time = (starts - cargroup.wait_period.minutes)
			end_time = (ends + cargroup.wait_period.minutes)
			check = 0 if Carblock.count(:conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, start_time, start_time, start_time, end_time]) > 0
		end
		
		# Check Inventory
		if check == 1
			start_time = starts
			end_time = ends
			carmovements = []
			if starts != starts_was || ends != ends_was
				if starts > ends_was + cargroup.wait_period.minutes || ends < starts_was - cargroup.wait_period.minutes
					# Non Overlapping Reschedule
					start_time -= cargroup.wait_period.minutes
					end_time += cargroup.wait_period.minutes
					carmovements << [Carmovement.find(:all, :conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, start_time, start_time, start_time, end_time]), start_time, end_time]
				else
					# Overlapping Reschedule
					if starts < starts_was
						start_time -= cargroup.wait_period.minutes
						carmovements << [Carmovement.find(:all, :conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, start_time, start_time, start_time, starts_was]), start_time, starts_was]
					end
					if ends > ends_was
						end_time += cargroup.wait_period.minutes
						carmovements << [Carmovement.find(:all, :conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, ends_was, ends_was, ends_was, end_time]), ends_was, end_time]
					end
				end
			else
				start_time -= cargroup.wait_period.minutes
				end_time += cargroup.wait_period.minutes
				carmovements << [Carmovement.find(:all, :conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, start_time, start_time, start_time, end_time]), start_time, end_time]
			end
			Inventory.connection.clear_query_cache
			ActiveRecord::Base.connection.execute("LOCK TABLES inventories WRITE")
			carmovements.uniq.each do |ar|
				starts_tmp = ar[1]
				ends_tmp = ar[2]
				ar[0].each do |cm|
					if check == 1
						start_time = (cm.starts > starts_tmp) ? cm.starts : starts_tmp
						end_time = (cm.ends < ends_tmp) ? cm.ends : ends_tmp
						tmp = Inventory.check(city, self.cargroup_id, cm.location_id, start_time, end_time)
						check = 0 if tmp == 0
					end
				end
			end
			ActiveRecord::Base.connection.execute("UNLOCK TABLES")
		end
		return check
	end
	
	def manage_inventory(starts_was, ends_was, starts, ends, block)
		check = 1
		cargroup = self.cargroup
		
		# Check Carblock
		if block
			if starts != starts_was || ends != ends_was
				if starts > ends_was + cargroup.wait_period.minutes || ends < starts_was - cargroup.wait_period.minutes
					# Non Overlapping Reschedule
					start_time = (starts - cargroup.wait_period.minutes)
					end_time = (ends + cargroup.wait_period.minutes)
					check = 0 if Carblock.count(:conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, start_time, start_time, start_time, end_time]) > 0
				else
					# Overlapping Reschedule
					if starts < starts_was
						start_time = (starts - cargroup.wait_period.minutes)
						check = 0 if Carblock.count(:conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, start_time, start_time, start_time, starts_was]) > 0
					end
					if check == 1 && ends > ends_was
						end_time = (ends + cargroup.wait_period.minutes)
						check = 0 if Carblock.count(:conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, ends_was, ends_was, ends_was, end_time]) > 0
					end
				end
			else
				start_time = (starts - cargroup.wait_period.minutes)
				end_time = (ends + cargroup.wait_period.minutes)
				check = 0 if Carblock.count(:conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, start_time, start_time, start_time, end_time]) > 0
			end
		end
		
		# Get Carmovements
		carmovements = []
		carmovements_m = []
		if check == 1
			start_time = starts
			end_time = ends
			if starts != starts_was || ends != ends_was
				if starts > ends_was + cargroup.wait_period.minutes || ends < starts_was - cargroup.wait_period.minutes
					# Non Overlapping Reschedule
					start_time -= cargroup.wait_period.minutes
					end_time += cargroup.wait_period.minutes
					cm = Carmovement.find(:all, :conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, start_time, start_time, start_time, end_time])
					carmovements << [cm, start_time, end_time]
					carmovements_m << [cm, starts, ends]
				else
					# Overlapping Reschedule
					if starts < starts_was
						start_time -= cargroup.wait_period.minutes
						cm = Carmovement.find(:all, :conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, start_time, start_time, start_time, starts_was])
						carmovements << [cm, start_time, starts_was]
						carmovements_m << [cm, starts, starts_was]
					elsif starts > starts_was
						cm = Carmovement.find(:all, :conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, starts_was, starts_was, starts_was, starts])
						carmovements_m << [cm, starts_was, starts]
					end
					if ends > ends_was
						end_time += cargroup.wait_period.minutes
						cm = Carmovement.find(:all, :conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, ends_was, ends_was, ends_was, end_time])
						carmovements << [cm, ends_was, end_time]
						carmovements_m << [cm, ends_was, ends]
					elsif ends < ends_was
						cm = Carmovement.find(:all, :conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, ends, ends, ends, ends_was])
						carmovements_m << [cm, ends, ends_was]
					end
				end
			else
				start_time -= cargroup.wait_period.minutes
				end_time += cargroup.wait_period.minutes
				cm = Carmovement.find(:all, :conditions => ["car_id = ? AND ((starts <= ? AND ends > ?) OR (starts >= ? AND starts <= ?))", self.id, start_time, start_time, start_time, end_time])
				carmovements << [cm, start_time, end_time]
				carmovements_m << [cm, starts, ends]
			end
		end
		
		Inventory.connection.clear_query_cache
		ActiveRecord::Base.connection.execute("LOCK TABLES inventories WRITE")
		# Check Inventory
		if block
			carmovements.uniq.each do |ar|
				starts_tmp = ar[1]
				ends_tmp = ar[2]
				ar[0].each do |cm|
					if check == 1
						start_time = (cm.starts > starts_tmp) ? cm.starts : starts_tmp
						end_time = (cm.ends < ends_tmp) ? cm.ends : ends_tmp
						tmp = Inventory.check(1, self.cargroup_id, cm.location_id, start_time, end_time)
						check = 0 if tmp == 0
					end
				end
			end
		end
			
		if check == 1
			carmovements_m.uniq.each do |ar|
				starts_tmp = ar[1]
				ends_tmp = ar[2]
				ar[0].each do |cm|
					start_time = (cm.starts > starts_tmp) ? cm.starts : starts_tmp
					end_time = (cm.ends < ends_tmp) ? cm.ends : ends_tmp
					if block
						# Block
						Inventory.block(self.cargroup_id, cm.location_id, start_time, end_time)
					else	
						# Release Inventory
						Inventory.release(self.cargroup_id, cm.location_id, start_time, end_time)
					end
				end
			end
		end
		ActiveRecord::Base.connection.execute("UNLOCK TABLES")
		return check
	end
	
end
