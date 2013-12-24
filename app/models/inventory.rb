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
		check = check(starts, ends, cargroup, location)[0][0][0][1][0]
		block_plain(cargroup, location, starts, ends) if check == 1
		return check
	end
	
	def self.block_extension(cargroup, location, starts, ends)
		check = check_extension(starts, ends, cargroup, location)[0][0][0][1][0]
		block_plain(cargroup, location, starts, ends) if check == 1
		return check
	end
	
	def self.block_plain(cargroup, location, starts, ends)
		ActiveRecord::Base.connection.execute("UPDATE inventories SET total = (total-1) WHERE 
			cargroup_id = #{cargroup} AND 
			location_id = #{location} AND 
			slot >= '#{(starts + 330.minutes).to_s(:db)}' AND 
			slot < '#{(ends + 330.minutes).to_s(:db)}'")
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
		if cargroup
			cars = [Cargroup.find(cargroup)]
		else
			cars = Cargroup.list
		end
		location = Location.find(location) if location
		h = []
		cars.each do |c|
			if location
				locs = [location]
			else
				locs = c.locations
			end
			check = {}
			locs.each do |l|
				check[l.id.to_s] = [1, l]
			end
			day = nil
			date = start_time + 330.minutes - c.wait_period.minutes
			while date.to_i < (end_time.to_i + 330.minutes.to_i + c.wait_period.minutes.to_i) do
				if day != date.to_date
					day = date.to_date
					inv = Inventory.get(c.id, day)
				end
				locs.each do |l|
					check[l.id.to_s][0] = 0 if inv[l.id.to_s][date.to_i.to_s] == 0
				end
				date += 15.minutes
			end
			h << [check.to_a, c]
		end
		return h
	end
	
	def self.check_extension(start_time, end_time, cargroup, location)
		if cargroup
			cars = [Cargroup.find(cargroup)]
		else
			cars = Cargroup.list
		end
		location = Location.find(location) if location
		h = []
		cars.each do |c|
			if location
				locs = [location]
			else
				locs = c.locations
			end
			check = {}
			locs.each do |l|
				check[l.id.to_s] = [1, l]
			end
			day = nil
			date = start_time + 330.minutes
			while date.to_i < (end_time.to_i + 330.minutes.to_i + c.wait_period.minutes.to_i) do
				if day != date.to_date
					day = date.to_date
					inv = Inventory.get(c.id, day)
				end
				locs.each do |l|
					check[l.id.to_s][0] = 0 if inv[l.id.to_s][date.to_i.to_s] == 0
				end
				date += 15.minutes
			end
			h << [check.to_a, c]
		end
		return h
	end
	
	def self.get(cargroup, day)
		date = day.to_datetime
		Rails.cache.fetch("inventory-#{cargroup}-#{date.to_i}") do
			h = {}
			l = nil
			tmp = {}
			Inventory.find_by_sql("SELECT slot, total, location_id FROM inventories 
				WHERE cargroup_id = #{cargroup} AND 
				slot >= '#{date.to_s(:db)}' AND 
				slot < '#{(date + 1.days).to_s(:db)}' 
				ORDER BY location_id ASC, slot ASC").each do |i|
				if l && l != i.location_id
					h[l.to_s] = tmp
					tmp = {}
				end
				l = i.location_id if l != i.location_id
				tmp[i.slot.to_i.to_s] = i.total
			end
			h[l.to_s] = tmp
			return h
		end
	end
	
	def self.release(cargroup, location, starts, ends)
		ActiveRecord::Base.connection.execute("UPDATE inventories SET total = (total+1) WHERE 
			cargroup_id = #{cargroup} AND 
			location_id = #{location} AND 
			slot >= '#{(starts + 330.minutes).to_s(:db)}' AND 
			slot < '#{(ends + 330.minutes).to_s(:db)}'")
	end
	
	private
	
	def after_save_tasks
		self.manage_cache
	end

end
