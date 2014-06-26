class Inventory < ActiveRecord::Base
	
	#establish_connection "#{Rails.env}_inventory"	
	
	belongs_to :cargroup
	belongs_to :city
	belongs_to :location
	
	validates :cargroup_id, :city_id, :location_id, :total, :slot, presence: true
	validates :cargroup_id, uniqueness: {scope: [:location_id, :slot]}
	
	after_save :after_save_tasks
	
	def self.block(city, cargroup, location, starts, ends)
		check = check(starts, ends, city, cargroup, location)
		block_plain(city, cargroup, location, starts, ends) if check == 1
		return check
	end
	
	def self.block_extension(city, cargroup, location, starts, ends)
		check = check_extension(starts, ends, city, cargroup, location)
		block_plain(city, cargroup, location, starts, ends) if check == 1
		return check
	end
	
	def self.block_plain(city, cargroup, location, starts, ends)
		Inventory.connection.execute("LOCK TABLES inventories WRITE")
		Rails.logger.warn "Inventory_block_cg_#{cargroup}_loc_#{location}: starts #{(starts + 330.minutes).to_s(:db)}, ends #{(ends + 330.minutes).to_s(:db)}"
		Inventory.connection.execute("UPDATE inventories SET total = (total-1) WHERE 
			cargroup_id = #{cargroup} AND 
			location_id = #{location} AND 
			slot >= '#{(starts + 330.minutes).to_s(:db)}' AND 
			slot < '#{(ends + 330.minutes).to_s(:db)}'")
		Inventory.connection.execute("UNLOCK TABLES")
	end
	
	def self.check(start_time, end_time, city, cargroup, location)
		if !cargroup.blank? && !location.blank?
			return check_plain(start_time, end_time, city, cargroup, location, true, true, true)[cargroup.to_s][location.to_s]
		else
			return check_plain(start_time, end_time, city, cargroup, location, true, true, true)
		end
	end
	
	def self.check_extension(start_time, end_time, city, cargroup, location)
		return check_plain(start_time, end_time, city, cargroup, location, true, false, true)[cargroup.to_s][location.to_s]
	end
	
	def self.check_plain(start_time, end_time, city, cargroup, location, timezone_padding=false, start_padding=false, end_padding=false)
		Inventory.connection.clear_query_cache
		Inventory.connection.execute("LOCK TABLES inventories WRITE, cargroups READ, locations READ, locations AS l READ, cities AS ct READ, cars AS c READ")
		if cargroup
			cars = [Cargroup.find(cargroup)]
		else
			cars = Cargroup.list(city)
		end
		if location
			locs = [Location.find(location)]
		else
			locs = Location.live(city)
		end
		check = {}
		cars.each do |c|
			tmp = {}
			locs.each do |l|
				if !l.block_time.blank? && (Time.now + l.block_time.minutes > start_time)
					tmp[l.id.to_s] = 0
				else
					tmp[l.id.to_s] = 1
				end
			end
			start_date = start_time
			start_date += 330.minutes if timezone_padding
			start_date -= c.wait_period.minutes if start_padding 
		
			end_date = end_time
			end_date += 330.minutes if timezone_padding
			end_date += c.wait_period.minutes if end_padding
			
			Inventory.find_by_sql("SELECT slot, total, location_id FROM inventories 
				WHERE cargroup_id = #{c.id} AND 
				location_id IN (#{locs.collect {|l| l.id}.join(',')}) AND 
				slot >= '#{start_date.to_s(:db)}' AND 
				slot < '#{(end_date).to_s(:db)}' AND 
				total < 1 
				GROUP BY location_id").each do |i|
				tmp[i.location_id.to_s] = 0
			end
			check[c.id.to_s] = tmp
		end
		Inventory.connection.execute("UNLOCK TABLES")
		return check
	end
	
	def self.get(city, cargroup, location, starts, ends, page)
		cg = Cargroup.find(cargroup)
		starts = starts.to_date.to_datetime
		if ends == ends.beginning_of_day
			ends = ends.to_date.to_datetime - 1.days
		else
			ends = ends.to_date.to_datetime
		end
		ends = ends + 1.days
		if page > 0
			starts = ends + (page-1).days
			ends += page.days
		elsif page < 0
			ends = starts + (page+1).days
			starts = starts + page.days
		else
			starts -= (cg.wait_period.minutes + 15.minutes)
			ends += (cg.wait_period.minutes + 15.minutes)
		end
		starts = Time.today if starts < Time.today
		if ends > Time.today || ends <= Time.today + CommonHelper::BOOKING_WINDOW.days
			Inventory.connection.clear_query_cache
			Inventory.connection.execute("LOCK TABLES inventories WRITE")
			temp = Inventory.find_by_sql("SELECT slot, total FROM inventories 
				WHERE cargroup_id = #{cargroup} AND location_id = #{location} AND 
				slot >= '#{starts.to_s(:db)}' AND 
				slot < '#{ends.to_s(:db)}' 
				ORDER BY slot ASC")
			Inventory.connection.execute("UNLOCK TABLES")
		else
			temp = []
		end
		return temp
	end
	
	def self.release(city, cargroup, location, starts, ends)
		Inventory.connection.execute("LOCK TABLES inventories WRITE")
		Rails.logger.warn "Inventory_release_cg_#{cargroup}_loc_#{location}: starts #{(starts + 330.minutes).to_s(:db)}, ends #{(ends + 330.minutes).to_s(:db)}"
		Inventory.connection.execute("UPDATE inventories SET total = (total+1) WHERE 
			cargroup_id = #{cargroup} AND 
			location_id = #{location} AND 
			slot >= '#{(starts + 330.minutes).to_s(:db)}' AND 
			slot < '#{(ends + 330.minutes).to_s(:db)}'")
		Inventory.connection.execute("UNLOCK TABLES")
	end
	
	private
	
	def after_save_tasks
	end

end
