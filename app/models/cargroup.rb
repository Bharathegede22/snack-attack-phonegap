class Cargroup < ActiveRecord::Base
	
	has_many :bookings
	
	def active_pricing(city)
		Rails.cache.fetch("cargroup-pricing-#{city}") do
			Pricing.find_by_sql("SELECT * FROM pricings 
				WHERE city_id = #{city} AND cargroup_id = #{self.id} AND status = 1 AND starts >= '#{Time.today.to_s(:db)}' 
				ORDER BY starts DESC
			")
		end
	end
	
	def check_fare(start_date, end_date)
		temp = {:estimate => 0, :discount => 0, :days => 0, :normal_days => 0, :discounted_days => 0, :hours => 0, :normal_hours => 0, :discounted_hours => 0, :kms => 0}
		cargroup = self
		h = (end_date.to_i - start_date.to_i)/3600
		h += 1 if (end_date.to_i - start_date.to_i) > h*3600
		d = h/24
		h = h - d*24
		temp[:days] = d
		temp[:hours] = h
		
		if d > 0
			if d >= 28
				# Monthly
				h = d*24 + h
				temp[:estimate] = ((cargroup.monthly_fare/(28*24.0))*h).round
				temp[:kms] = ((cargroup.monthly_km_limit/(28*24.0))*h).round
				return temp
			elsif d >= 7
				# Weekly
				h = d*24 + h
				temp[:estimate] = ((cargroup.weekly_fare/(7*24.0))*h).round
				temp[:kms] = ((cargroup.weekly_km_limit/(7*24.0))*h).round
				return temp
			else
				# Daily Fair
				(0..(d-1)).each do |i|
					wday = (start_date + i.days).wday
					temp[:estimate] += cargroup.daily_fare
					temp[:kms] += cargroup.daily_km_limit
					if wday > 0 && wday < 5
						temp[:discount] += cargroup.daily_fare*(CommonHelper::WEEKDAY_DISCOUNT/100.0)
						temp[:discounted_days] += 1
					else
						temp[:normal_days] += 1
					end
				end
			end
		end
		# Hourly Fair
		wday = (start_date + d.days).wday
		if h <= 10
			tmp = cargroup.hourly_fare*h
		else
			tmp = cargroup.daily_fare
		end
		temp[:estimate] += tmp
		if wday > 0 && wday < 5
			temp[:discount] += tmp*(CommonHelper::WEEKDAY_DISCOUNT/100.0)
			temp[:discounted_hours] += h
		else
			temp[:normal_hours] += h
		end
		temp[:kms] += ((cargroup.hourly_km_limit*h) < cargroup.daily_km_limit) ? (cargroup.hourly_km_limit*h) : cargroup.daily_km_limit
		temp[:estimate] = temp[:estimate].round
		temp[:discount] = temp[:discount].round
		temp[:kms] = temp[:kms].round
		return temp
	end
	
	def check_late(end_date_old, end_date_new)
		data = {:hours => 0, :billed_hours => 0, :standard_hours => 0, :discounted_hours => 0, :estimate => 0, :discount => 0}
		if end_date_old < end_date_new
			cargroup = self
			rate = cargroup.hourly_fare
			data[:hours] = (end_date_new.to_i - end_date_old.to_i)/3600
			data[:hours] += 1 if (end_date_new.to_i - end_date_old.to_i) > data[:hours]*3600
			data[:billed_hours] += data[:hours]
			min = 1
			wday = end_date_old.wday
			while min <= data[:hours]*60
				if min == ((min/60)*60)
					data[:estimate] += rate
					if [0,5,6].include?(wday)
						data[:standard_hours] += 1
					else
						data[:discounted_hours] += 1
						data[:discount] += rate*(CommonHelper::WEEKDAY_DISCOUNT/100.0)
					end
					wday = (end_date_old + min.minutes).wday
				end
				min += 1
			end
		end
	end
	
	def cargroupObj
  	return Cargroup.where("status = 1").order("priority ASC")
  end  
	
	def encoded_id
		CommonHelper.encode('cargroup', self.id)
	end
	
	def h1(city)
		return "Hire #{self.name}"
	end
	
	def link(city)
		return "http://www.zoomcar.in/" + CommonHelper.escape(city.name.downcase) + "/" + CommonHelper.escape(self.name.downcase) + "-car-rental_" + self.encoded_id
	end
	
	def locations(city)
  	Rails.cache.fetch("cargroup-locations-#{city.id}-#{self.id}") do
		 	Location.find_by_sql("SELECT l.* FROM locations l 
		 		INNER JOIN cars c ON c.location_id = l.id 
		 		WHERE c.cargroup_id = #{self.id} AND c.status > 0 AND l.status > 0 AND l.city_id = #{city.id} 
		 		GROUP BY l.id 
		 		ORDER BY l.id DESC")
		end
  end
  
  def locations_hash(city)
  	tmp = {}
  	self.locations(city).each do |l|
  		tmp[l.id.to_s] = 1
  	end
  	return tmp
  end
  
  def meta_description(city)
		return "Self drive #{self.name.downcase} car on hire by the hour, daily, weekly and monthly basis at affordable price in #{city.name}"
	end
	
	def meta_keywords(city)
		@meta_keywords = "self drive car #{self.name.downcase} #{city.name.downcase}, zoomcar"
	end
	
	def meta_title(city)
		return "#{self.name} Car On Self Drive In #{city.name} | Zoomcar"
	end
	
	def self.list(city)
  	Rails.cache.fetch("cargroup-list-#{city.id}") do
  		Cargroup.find_by_sql("SELECT cg.* FROM cargroups cg 
				INNER JOIN cars c ON c.cargroup_id = cg.id 
				INNER JOIN locations l ON l.id = c.location_id 
				WHERE cg.status > 0 AND c.status > 0 AND l.status > 0 AND l.city_id = #{city.id} 
				GROUP BY cg.id
				ORDER BY cg.priority ASC
			")
  	end
  end
	
	def self.live(city)
		Cargroup.find_by_sql("SELECT cg.*, l.name AS l_name, l.id AS l_id, COUNT(DISTINCT c.id) AS total FROM cargroups cg 
			INNER JOIN cars c ON c.cargroup_id = cg.id 
			INNER JOIN locations l ON l.id = c.location_id 
			WHERE cg.status > 0 AND c.status > 0 AND l.status > 0 AND l.city_id = #{city.id} 
			GROUP BY cg.id, l.id 
			ORDER BY cg.priority ASC")
	end
	
  def self.random(city)
  	Cargroup.list(city).sample
  end
  
	def shortname
		self.display_name.gsub('Mahindra ','') rescue ""
	end
	
end
