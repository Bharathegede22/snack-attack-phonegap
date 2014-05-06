class Inventory < ActiveRecord::Base
	
	belongs_to :cargroup
	belongs_to :city
	belongs_to :location
	
	validates :cargroup_id, :city_id, :location_id, :total, :slot, presence: true
	validates :cargroup_id, uniqueness: {scope: [:location_id, :slot]}
	
	after_save :after_save_tasks
	
	def manage_cache
		Rails.cache.delete("inventory-#{self.cargroup_id}-#{self.location_id}-#{self.slot.beginning_of_day.to_i}")
	end
	
	def self.block(cargroup, location, starts, ends)
		check = check(starts, ends, cargroup, location)
		block_plain(cargroup, location, starts, ends) if check == 1
		return check
	end
	
	def self.block_extension(cargroup, location, starts, ends)
		check = check_extension(starts, ends, cargroup, location)
		block_plain(cargroup, location, starts, ends) if check == 1
		return check
	end
	
	def self.block_plain(cargroup, location, starts, ends)
		ActiveRecord::Base.connection.execute("LOCK TABLES inventories WRITE")
		ActiveRecord::Base.connection.execute("UPDATE inventories SET total = (total-1) WHERE 
			cargroup_id = #{cargroup} AND 
			location_id = #{location} AND 
			slot >= '#{(starts + 330.minutes).to_s(:db)}' AND 
			slot < '#{(ends + 330.minutes).to_s(:db)}'")
		ActiveRecord::Base.connection.execute("UNLOCK TABLES")
	end
	
	def self.cache
		start_date = '2013-11-01 00:00:00'.to_datetime
		end_date = '2014-04-01 00:00:00'.to_datetime
		Cargroup.find(:all).each do |car|
			Location.find(:all).each do |loc|
				date = start_date
				while date < end_date do
					Inventory.get(car.id, loc.id, date)
					date += 1.days
				end
			end
		end
	end
	
	def self.check(start_time, end_time, cargroup, location)
		if !cargroup.blank? && !location.blank?
			return check_plain(start_time, end_time, cargroup, location, true, true, true)[cargroup.to_s][location.to_s]
		else
			return check_plain(start_time, end_time, cargroup, location, true, true, true)
		end
	end
	
	def self.check_extension(start_time, end_time, cargroup, location)
		return check_plain(start_time, end_time, cargroup, location, true, false, true)[cargroup.to_s][location.to_s]
	end
	
	def self.check_plain(start_time, end_time, cargroup, location, timezone_padding=false, start_padding=false, end_padding=false)
		Inventory.connection.clear_query_cache
		ActiveRecord::Base.connection.execute("LOCK TABLES inventories WRITE, cargroups READ, locations READ, locations AS l READ, cars AS c READ")
		if cargroup
			cars = [Cargroup.find(cargroup)]
		else
			cars = Cargroup.list
		end
		if location
			locs = [Location.find(location)]
		else
			locs = Location.live
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
		ActiveRecord::Base.connection.execute("UNLOCK TABLES")
		return check
	end
	
	def self.get(cargroup, location, starts, ends, page)
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
			ActiveRecord::Base.connection.execute("LOCK TABLES inventories WRITE")
			temp = Inventory.find_by_sql("SELECT slot, total FROM inventories 
				WHERE cargroup_id = #{cargroup} AND location_id = #{location} AND 
				slot >= '#{starts.to_s(:db)}' AND 
				slot < '#{ends.to_s(:db)}' 
				ORDER BY slot ASC")
			ActiveRecord::Base.connection.execute("UNLOCK TABLES")
		else
			temp = []
		end
		return temp
	end
	
	def self.release(cargroup, location, starts, ends)
		ActiveRecord::Base.connection.execute("LOCK TABLES inventories WRITE")
		ActiveRecord::Base.connection.execute("UPDATE inventories SET total = (total+1) WHERE 
			cargroup_id = #{cargroup} AND 
			location_id = #{location} AND 
			slot >= '#{(starts + 330.minutes).to_s(:db)}' AND 
			slot < '#{(ends + 330.minutes).to_s(:db)}'")
		ActiveRecord::Base.connection.execute("UNLOCK TABLES")
	end
	
	private
	
	def after_save_tasks
		self.manage_cache
	end

end
