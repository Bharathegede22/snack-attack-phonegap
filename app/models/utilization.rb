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
	
	def self.manage(id)
		booking = Booking.find(id)
		if booking.jsi.blank? && booking.status == 0
			rev = 0
		else
			rev = booking.revenue
		end
		if rev <= 0
			Utilization.find(:all, :conditions => ["booking_id = ?", booking.id]).each do |v|
				v.car_id = booking.car_id
				v.cargroup_id = booking.cargroup_id
				v.minutes = 0
				v.billed_minutes = 0
				v.billed_minutes_last = 0
				v.revenue = 0
				v.revenue_last = 0
				v.save!
			end
		else
			array = []
			if !booking.returned_at.blank?
				ends = booking.returned_at
			else
				ends = booking.ends
			end
			m = (ends.to_i - booking.starts.to_i)/60
			h = m/60
			h += 1 if (ends.to_i - booking.starts.to_i) > h*3600
			start = booking.starts
			min = 0
			billed = 0
			temp = 0
			daily = 0
			wday = start.wday
			date = start.to_date
			while min <= (h*60)
				if min > 0
					billed = 0 if (min-((min/1440)*1440)) == 0
					if ((((start + min.minutes).hour == 0) && ((start + min.minutes).min == 0)) || (min == h*60))
						array << [date, wday, daily, temp]
						temp = 0
						daily = 0
						wday = (start + min.minutes).wday
						date = (start + min.minutes).to_date
					end
				end
				min += 1
				temp += 1 if billed < 600
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
				a = Utilization.new(:booking_id => booking.id, :location_id => booking.location_id, :wday => u[1], :day => u[0]) if !a
				a.car_id = booking.car_id
				a.cargroup_id = booking.cargroup_id
				a.minutes = u[2]
				a.billed_minutes = u[3]
				a.revenue = ((rev/(h*60.0))*u[2]).round
				tmp << a
				temp.delete(u[0].to_datetime.to_i.to_s)
			end
			tmp.each do |u|
				u.save!
			end
			temp.each do |k,v|
				v.car_id = booking.car_id
				v.cargroup_id = booking.cargroup_id
				v.minutes = 0
				v.billed_minutes = 0
				v.billed_minutes_last = 0
				v.revenue = 0
				v.revenue_last = 0
				v.save!
			end
		end
	end
	
	def weekday
		Date::DAYNAMES[self.wday]
	end
	
end
