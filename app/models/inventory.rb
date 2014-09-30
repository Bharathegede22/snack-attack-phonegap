class Inventory < ActiveRecord::Base
	
	belongs_to :cargroup
	belongs_to :city
	belongs_to :location
	
	def self.block(cargroup, location, starts, ends, change_max=false)
		return if starts.to_i > ends.to_i
		# Timezone padding
		starts += 330.minutes
		ends += 330.minutes
		if change_max
			opr = "total = (total-1), max = (max-1)"
		else
			opr = "total = (total-1)"
		end
		INVENTORY_LOGGER.error "Inventory_block_cg_#{cargroup}_loc_#{location}: starts #{(starts).to_s(:db)}, ends #{(ends).to_s(:db)}"
		ActiveRecord::Base.connection.execute("UPDATE inventories SET #{opr} WHERE 
			cargroup_id = #{cargroup} AND 
			location_id = #{location} AND 
			slot >= '#{(starts).to_s(:db)}' AND 
			slot < '#{(ends).to_s(:db)}'")
	end
	
	def self.check(city, cargroup, location, starts, ends)
		# Timezone padding
		starts += 330.minutes
		ends += 330.minutes
		if Inventory.find_by_sql("SELECT slot, total, cargroup_id, location_id FROM inventories 
			WHERE cargroup_id = #{cargroup} AND 
			location_id = #{location} AND 
			slot >= '#{starts.to_s(:db)}' AND 
			slot < '#{(ends).to_s(:db)}' AND 
			total < 1 
			LIMIT 10").length > 0
			h = 0
		else
			h = 1
		end
		return h
	end
	
	def self.do_block(city, cargroup, location, starts, ends, change_max=false)
		Inventory.connection.clear_query_cache
		ActiveRecord::Base.connection.execute("LOCK TABLES inventories WRITE")
		tmp = check(city, cargroup, location, starts, ends)
		block(cargroup, location, starts, ends, change_max) if tmp == 1
		ActiveRecord::Base.connection.execute("UNLOCK TABLES")
		return tmp
	end
	
	def self.do_check(city, cargroup, location, starts, ends)
		Inventory.connection.clear_query_cache
		ActiveRecord::Base.connection.execute("LOCK TABLES inventories WRITE, cargroups READ")
		tmp = check(city, cargroup, location, starts, ends)
		ActiveRecord::Base.connection.execute("UNLOCK TABLES")
		return tmp
	end
	
	def self.do_release(cargroup, location, starts, ends, change_max=false)
		Inventory.connection.clear_query_cache
		ActiveRecord::Base.connection.execute("LOCK TABLES inventories WRITE")
		release(cargroup, location, starts, ends, change_max)
		ActiveRecord::Base.connection.execute("UNLOCK TABLES")
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
	
	def self.release(cargroup, location, starts, ends, change_max=false)
		return if starts > ends
		# Timezone Padding
		starts += 330.minutes
		ends += 330.minutes
		if change_max
			opr = "total = (total+1), max = (max+1)"
		else
			opr = "total = (total+1)"
		end
		INVENTORY_LOGGER.error "Inventory_release_cg_#{cargroup}_loc_#{location}: starts #{(starts).to_s(:db)}, ends #{(ends).to_s(:db)}"
		ActiveRecord::Base.connection.execute("UPDATE inventories SET #{opr} WHERE 
			cargroup_id = #{cargroup} AND 
			location_id = #{location} AND 
			slot >= '#{starts.to_s(:db)}' AND 
			slot < '#{ends.to_s(:db)}'")
	end
	
	def self.search(city, starts, ends)
		cars = Cargroup.list(city)
		locs = Location.live(city)
		check = {}
		cars.each do |c|
			tmp = {}
			locs.each do |l|
				if !l.block_time.blank? && (Time.now + l.block_time.minutes > starts)
					tmp[l.id.to_s] = 0
				else
					tmp[l.id.to_s] = 1
				end
			end
			start_date = starts
			start_date += 330.minutes
			start_date -= c.wait_period.minutes
		
			end_date = ends
			end_date += 330.minutes
			end_date += c.wait_period.minutes
			
			Inventory.connection.clear_query_cache
			ActiveRecord::Base.connection.execute("LOCK TABLES inventories WRITE")
			Inventory.find_by_sql("SELECT slot, total, location_id FROM inventories 
				WHERE cargroup_id = #{c.id} AND 
				location_id IN (#{locs.collect {|l| l.id}.join(',')}) AND 
				slot >= '#{start_date.to_s(:db)}' AND 
				slot < '#{(end_date).to_s(:db)}' AND 
				total < 1 
				GROUP BY location_id").each do |i|
				tmp[i.location_id.to_s] = 0
			end
			ActiveRecord::Base.connection.execute("UNLOCK TABLES")
			check[c.id.to_s] = tmp
		end
		Inventory.connection.execute("UNLOCK TABLES")
		return check
	end
	
end

# == Schema Information
#
# Table name: inventories
#
#  id          :integer          not null, primary key
#  cargroup_id :integer
#  location_id :integer
#  city_id     :integer
#  total       :integer          default(0)
#  slot        :datetime
#  max         :integer          default(0)
#
# Indexes
#
#  index_inventories_on_cargroup_id_and_location_id_and_slot  (cargroup_id,location_id,slot) UNIQUE
#  index_inventories_on_total                                 (total)
#
