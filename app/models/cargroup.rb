class Cargroup < ActiveRecord::Base
	
	has_many :bookings
	
  def cargroupObj
  	return Cargroup.where("status = 1").order("priority ASC")
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
		return data
	end
	
	def check_reschedule(start_date_old, start_date_new, end_date_old, end_date_new)
		start_date = start_date_new
		data = {:hours => 0, :billed_hours => 0, :standard_hours => 0, :discounted_hours => 0, :estimate => 0, :discount => 0}
		cargroup = self
		rate = {:hourly => (cargroup.hourly_fare/60.0), :daily => cargroup.daily_fare, :weekly => cargroup.weekly_fare, :monthly => cargroup.monthly_fare}
		
		# Old Values
		min_old = (end_date_old.to_i - start_date.to_i)/60
		hour_old = min_old/60
		hour_old += 1 if (end_date_old.to_i - start_date.to_i) > hour_old*3600
		
		# New Values
		min_new = (end_date_new.to_i - start_date.to_i)/60
		hour_new = min_new/60
		hour_new += 1 if (end_date_new.to_i - start_date.to_i) > hour_new*3600
		
		data[:hours] = hour_new - hour_old
		data[:days] = data[:hours]/24
		data[:hours] = data[:hours] - (data[:hours]/24)*24
		
		min = 0
		billed = 0
		billed_total = 0
		daily = {:actual => 0, :billed => 0}
		daily_last = {:actual => 0, :billed => 0}
		wday = start_date.wday
		wday_c = start_date.wday
		array = []
		rev = 0
		disc = 0
		
		if (hour_new/24) >= 7
			hour_process = 7*24
		else
			hour_process = hour_new
		end
		
		# Hourly / Daily Tariff
		if (hour_old/24) < 7
			while min <= (hour_process*60)
				if (min-((min/1440)*1440)) == 0
					billed = 0
					wday_c = (start_date + min.minutes).wday
				end
				if ((((start_date + min.minutes).hour == 0) && ((start_date + min.minutes).min == 0)) || (min == hour_process*60))
					if daily_last[:billed] > 0
						array_last = array.last
						if array_last && ((array_last + daily_last[:actual]) >= 600)
							rev = (rate[:daily] - ((600 - daily_last[:billed])*rate[:hourly]))
						else
							rev = daily_last[:billed]*rate[:hourly]
						end
						if [0,1,6].include?(wday)
							data[:standard_hours] += daily_last[:billed]/60
							disc = 0
						else
							data[:discounted_hours] += daily_last[:billed]/60
							disc = rev*(CommonHelper::WEEKDAY_DISCOUNT/100.0)
						end
						data[:estimate] += rev
						data[:discount] += disc
					end
					if daily[:billed] > 0
						if (daily[:actual] >= 600)
							rev = (rate[:daily] - ((600 - daily[:billed])*rate[:hourly]))
						else
							rev = daily[:billed]*rate[:hourly]
						end
						if [0,5,6].include?(wday)
							data[:standard_hours] += daily[:billed]/60
							disc = 0
						else
							data[:discounted_hours] += daily[:billed]/60
							disc = rev*(CommonHelper::WEEKDAY_DISCOUNT/100.0)
						end
						data[:estimate] += rev
						data[:discount] += disc
					end
					array << daily[:actual]
					daily = {:actual => 0, :billed => 0}
					daily_last = {:actual => 0, :billed => 0}
					wday = (start_date + min.minutes).wday
					date = (start_date + min.minutes).to_date
				end
				if billed < 600
					if wday == wday_c
						daily[:actual] += 1
						daily[:billed] += 1 if min >= (hour_old*60)
					else
						daily_last[:actual] += 1
						daily_last[:billed] += 1 if min >= (hour_old*60)
					end
					billed_total += 1 if min >= (hour_old*60)
				end
				billed += 1
				min += 1
			end
			data[:billed_hours] = billed_total/60
		end
		
		# Weekly Tariff
		if (hour_new/24) >= 7 && (hour_old/24) < 28
			if (hour_new/24) >= 28
				hour_process = 21*24
			else
				hour_process = hour_new - (24*7)
			end
			hour_process -= (hour_old - (24*7)) if (hour_old/24) >= 7
			data[:estimate] += (hour_process * (rate[:weekly]/(7*24.0)))
			data[:billed_hours] += hour_process
		end
		
		# Monthly Tariff
		if (hour_new/24) >= 28
			hour_process = hour_new - (24*28)
			hour_process -= (hour_old - (24*28)) if (hour_old/24) >= 28
			data[:estimate] += (hour_process * (rate[:monthly]/(28*24.0)))
			data[:billed_hours] += hour_process
		end
		#debugger
		data[:estimate] = data[:estimate].round
		data[:discount] = data[:discount].round
		return data
	end
	
	def encoded_id
		CommonHelper.encode('cargroup', self.id)
	end
	
	def h1(city)
		return "Hire #{self.name} In #{city.name}"
	end
	
	def link(city)
		return "http://www.zoomcar.in/" + CommonHelper.escape(city.name.downcase) + "/" + CommonHelper.escape(self.name.downcase) + "-car-rental_" + self.encoded_id
	end
	
	def locations
  	Rails.cache.fetch("cargroup-locations-#{self.id}") do
		 	Location.find_by_sql("SELECT l.* FROM locations l 
		 		INNER JOIN cars c ON c.location_id = l.id 
		 		WHERE c.cargroup_id = #{self.id} AND c.status > 0 AND l.status > 0 
		 		GROUP BY l.id 
		 		ORDER BY l.id DESC")
		end
  end
  
  def locations_hash
  	tmp = {}
  	self.locations.each do |l|
  		tmp[l.id.to_s] = 1
  	end
  	return tmp
  end
  
  def meta_description(city)
		return "Hire #{self.name.downcase} for self drive in #{city.name}. All-inclusive tariff covers fuel, insurance & taxes"
	end
	
	def meta_keywords(city)
		@meta_keywords = "self drive car #{self.name.downcase} #{city.name.downcase}, zoomcar"
	end
	
	def meta_title(city)
		return "Hire #{self.name} For Self Drive In #{city.name} | Zoomcar.in"
	end
	
	def self.list
  	Rails.cache.fetch("cargroup-list") do
  		Cargroup.find_by_sql("SELECT * FROM cargroups WHERE status = 1 ORDER BY priority ASC")
  	end
  end
	
	def self.live(city_id=1)
		Cargroup.find_by_sql("SELECT cg.*, l.name AS l_name, l.id AS l_id, COUNT(DISTINCT c.id) AS total FROM cargroups cg 
			INNER JOIN cars c ON c.cargroup_id = cg.id 
			INNER JOIN locations l ON l.id = c.location_id 
			WHERE cg.status > 0 AND c.status > 0 AND l.status > 0 AND l.city_id = #{city_id} 
			GROUP BY cg.id, l.id 
			ORDER BY cg.priority ASC")
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
