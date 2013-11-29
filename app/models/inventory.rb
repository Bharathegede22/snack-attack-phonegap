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

	
	def self.block(cargroup, location, start_time, end_time,status)
		check = Inventory.check(cargroup, location, start_time, end_time)
		if check == 2			
				Inventory.find(:all, :conditions => ["cargroup_id = ? AND location_id = ? AND slot >= ? AND slot <= ?", cargroup, location, start_time, end_time]).each do |i|
					i.total -= 1 if status == 0
					i.total += 1 if statis == 1
					i.save!
				end			
		end
		return check
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

	
	def self.check(cargroup, location, start_time, end_time)
		check = true
		check_l = false
		day = nil
		date = start_time.to_datetime

		while date <= end_time.to_datetime do  
			if day != date.to_date
				day = date.to_date
				inv = Inventory.get(cargroup, location, day)
			end
			check_l = true if inv[date.to_i.to_s]
			check = false if !inv[date.to_i.to_s] || (inv[date.to_i.to_s] == 0)
			date += 15.minutes 
		end

		if check_l
			if check
				return 2
			else
				return 1
			end
		else
			return 0
		end
	end


	
	def self.get(cargroup, location, day)
		date = day.to_datetime
		Rails.cache.fetch("inventory-#{cargroup}-#{location}-#{date.to_i}") do
			h = Hash.new
			date = date - (5.hours + 30.minutes)                                          
			Inventory.find_by_sql("SELECT slot, total FROM inventories 
				WHERE cargroup_id = #{cargroup} AND 
				location_id = #{location} AND                                              
				slot >= '#{date.to_s(:db)}' AND 
				slot < '#{(date + 1.days).to_s(:db)}' 
				ORDER BY slot ASC").each do |i|
				h[i.slot.to_i.to_s] = i.total
			end
			return h
		end
	end


	#db queries is not cached


	def self.get_available_cars(booking)
		available_cars=Array.new

		if booking[:cargroup_id] == '' && booking[:location_id] == ''	
			cars=Car.find(:all,:group => "cargroup_id,location_id")			
			cars.each do |car| 
				booking[:cargroup_id] = car.cargroup_id 
				booking[:location_id] = car.location_id 
				if Inventory.check(booking[:cargroup_id],booking[:location_id],booking[:starts],booking[:ends]) == 2									
					available_cars << car 
				end
			end 
			return available_cars

		elsif booking[:cargroup_id] != '' && booking[:location_id] == ''		
			cars=Car.find(:all,:conditions => ["cargroup_id =?",booking[:cargroup_id]],:group => "cargroup_id,location_id")
			cars.each do |car|
				booking[:cargroup_id] = car.cargroup_id
				booking[:location_id] = car.location_id									
				if Inventory.check(booking[:cargroup_id],booking[:location_id],booking[:starts],booking[:ends]) == 2									
					available_cars << car 
				end							
			end 
			return available_cars

		elsif booking[:cargroup_id] == '' && booking[:location_id] != ''			
			cars=Car.find(:all,:conditions => ["location_id =?",booking[:location_id]],:group => "cargroup_id,location_id")
			cars.each do |car|
				booking[:cargroup_id] = car.cargroup_id
				booking[:location_id] = car.location_id									
				if Inventory.check(booking[:cargroup_id],booking[:location_id],booking[:starts],booking[:ends]) == 2									
					available_cars << car 
				end							
			end 
			return available_cars	

		else			
			return Car.find(:all,:conditions =>["cargroup_id  =? AND location_id = ?", 
				booking[:cargroup_id], booking[:location_id]],:group => "cargroup_id,location_id")
		end		
	end


	def self.seed
		start_date = '2013-11-01 00:00:00'.to_datetime
		end_date = '2014-01-01 00:00:00'.to_datetime
		Cargroup.find(:all).each do |car|
			Location.find(:all).each do |loc|
				num = Car.count(:conditions => ["cargroup_id = ? AND location_id = ?", car.id, loc.id])
				if num > 0
					date = start_date
					while date < end_date do
						inv = Inventory.create(:cargroup_id => car.id, :location_id => loc.id, :city_id => 1, :total => num, :slot => date)
						date += 15.minutes
					end
				end
			end
		end
	end
	
	private
	
	def after_save_tasks
		self.manage_cache
	end

end