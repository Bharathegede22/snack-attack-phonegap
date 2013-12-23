class Utilization < ActiveRecord::Base
	
	belongs_to :booking
	
	validates :booking_id, :cargroup_id, :location_id, presence: true
	validates :day, uniqueness: {scope: :booking_id}
	
	def billed
		return self.billed_minutes + self.billed_minutes_last
	end
	
	def rev
		return self.revenue + self.revenue_last
	end
	
	def self.manage(booking)
		if booking.status > 8
			Utilization.find(:all, :conditions => ["booking_id = ?", booking.id]).each do |v|
				v.minutes = 0
				v.billed_minutes = 0
				v.billed_minutes_last = 0
				v.revenue = 0
				v.revenue_last = 0
				v.save
			end
		else
			cargroup = booking.cargroup
			rate = cargroup.hourly_fare/60.0
			rate_d = cargroup.daily_fare
			array = []
			m = (booking.ends.to_i - booking.starts.to_i)/60
			h = m/60
			h += 1 if (booking.ends.to_i - booking.starts.to_i) > h*3600
			start = booking.starts
			min = 0
			billed = 0
			revenue = 0
			revenue_last = 0
			daily = 0
			temp = 0
			temp_last = 0
			wday = start.wday
			wday_c = start.wday
			date = start.to_date
			while min <= (h*60 + 1)
				if min > 0
					if (min-((min/1440)*1440)) == 0
						billed = 0
						wday_c = (start + min.minutes).wday
					end
					if ((((start + min.minutes).hour == 0) && ((start + min.minutes).min == 0)) || (min > h*60))
						array_last = array.last
						if array_last && !array_last.blank? && (array_last[3] + temp_last) >= 600
							if [0,1,6].include?(wday)
								revenue_last = rate_d - array_last[5]
							else
								revenue_last = (rate_d*0.65) - array_last[5]
							end
						end
						array << [date, wday, daily, temp, temp_last, revenue, revenue_last]
						temp = 0
						temp_last = 0
						daily = 0
						revenue = 0
						revenue_last = 0
						wday = (start + min.minutes).wday
						date = (start + min.minutes).to_date
					end
				end
				min += 1
				if billed < 600
					if wday == wday_c
						temp += 1
					else
						temp_last += 1
					end
					if wday == wday_c
						if wday_c > 0 && wday_c < 5
							revenue += rate*0.65
						else
							revenue += rate
						end
					else
						if wday_c > 0 && wday_c < 5
							revenue_last += rate*0.65
						else
							revenue_last += rate
						end
					end
				end
				billed += 1
				daily += 1
			end
			temp = {}
			Utilization.find(:all, :conditions => ["booking_id = ?", booking.id]).each do |u|
				temp[u.day.to_datetime.to_i.to_s] = u
			end
			tmp = []
			array.each do |u|
				a = temp[u[0].to_datetime.to_i.to_s]
				a = Utilization.new(:booking_id => booking.id, :cargroup_id => booking.cargroup_id, :location_id => booking.location_id, :wday => u[1], :day => u[0]) if !a
				a.minutes = u[2]
				a.billed_minutes = u[3]
				a.billed_minutes_last = u[4]
				a.revenue = u[5].round
				a.revenue_last = u[6].round
				tmp << a
				temp.delete(u[0].to_datetime.to_i.to_s)
			end
			tmp.each do |u|
				u.save
			end
			temp.each do |k,v|
				v.minutes = 0
				v.billed_minutes = 0
				v.billed_minutes_last = 0
				v.revenue = 0
				v.revenue_last = 0
				v.save
			end
		end
	end
	
	def weekday
		Date::DAYNAMES[self.wday]
	end
	
end
