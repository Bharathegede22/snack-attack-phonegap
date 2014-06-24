class Pricingv1 < Pricing
	#version = "v1"
	

	########## TARIFF CALCULATIONS##############
	def self.check_fare_calc(start_date, end_date, cargroup_id, city_id =1)
		version = "v1"
		temp = {:estimate => 0, :discount => 0, :days => 0, :normal_days => 0, :discounted_days => 0, :hours => 0, :normal_hours => 0, :discounted_hours => 0, :kms => 0}
		pricing = Pricing.where("cargroup_id = ? AND city_id = ? AND version = ?", cargroup_id, city_id, version).last rescue nil
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
				temp[:estimate] = ((pricing.monthly_fare/(28*24.0))*h).round
				temp[:kms] = ((pricing.monthly_kms/(28*24.0))*h).round
				return temp
			elsif d >= 7
				# Weekly
				h = d*24 + h
				temp[:estimate] = ((pricing.weekly_fare/(7*24.0))*h).round
				temp[:kms] = ((pricing.weekly_kms/(7*24.0))*h).round
				return temp
			else
				# Daily Fair
				(0..(d-1)).each do |i|
					wday = (start_date + i.days).wday
					temp[:estimate] += pricing.daily_fare
					temp[:kms] += pricing.daily_kms
					if wday > 0 && wday < 5
						temp[:discount] += pricing.daily_fare*(CommonHelper::WEEKDAY_DISCOUNT/100.0)
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
			tmp = pricing.hourly_fare*h
		else
			tmp = pricing.daily_fare
		end
		temp[:estimate] += tmp
		if wday > 0 && wday < 5
			temp[:discount] += tmp*(CommonHelper::WEEKDAY_DISCOUNT/100.0)
			temp[:discounted_hours] += h
		else
			temp[:normal_hours] += h
		end
		temp[:kms] += ((pricing.hourly_kms*h) < pricing.daily_kms) ? (pricing.hourly_kms*h) : pricing.daily_kms
		temp[:estimate] = temp[:estimate].round
		temp[:discount] = temp[:discount].round
		temp[:kms] = temp[:kms].round
		return temp
	end

	def self.check_late_calc(end_date_old, end_date_new, cargroup_id, city_id =1)
			version= "v1"
		data = {:hours => 0, :billed_hours => 0, :standard_hours => 0, :discounted_hours => 0, :estimate => 0, :discount => 0}
		if end_date_old < end_date_new
			pricing = Pricing.where("cargroup_id = ? AND city_id = ? AND version = ?", cargroup_id, city_id, version).last rescue nil
			rate = pricing.hourly_fare
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
	
	def self.check_reschedule_calc(start_date_old, start_date_new, end_date_old, end_date_new,cargroup_id,city_id=1)
		version ="v1"
		start_date = start_date_new
		data = {:hours => 0, :billed_hours => 0, :standard_hours => 0, :discounted_hours => 0, :estimate => 0, :discount => 0}
		pricing = Pricing.where("cargroup_id = ? AND city_id = ? AND version = ?", cargroup_id, city_id, version).last rescue nil
		rate = {:hourly => (pricing.hourly_fare/60.0), :daily => pricing.daily_fare, :weekly => pricing.weekly_fare, :monthly => pricing.monthly_fare}
		
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

	##########RESCHEDULE PRICING CALCULATIONS################
	def self.get_fare(action,booking)
		case action
		when 'early'
			start_date = booking.starts
			end_date_old = booking.returned_at
			end_date_new = booking.ends
		when 'extend'
			start_date = booking.starts
			end_date_old = booking.last_ends
			end_date_new = booking.ends
		when 'short'
			start_date = booking.starts
			end_date_old = booking.ends
			end_date_new = booking.last_ends
		end
		#city_id = 1
		data = {:hours => 0, :billed_hours => 0, :standard_hours => 0, :discounted_hours => 0, :estimate => 0, :discount => 0}
		#cargroup = self.cargroup
		#version = booking.version
		version ="v1"
		cargroup_id = booking.cargroup_id
		city_id = booking.location.city_id
		pricing = Pricing.where("cargroup_id = ? AND city_id = ? AND version = ?", cargroup_id, city_id, version).last rescue nil
		rate = {:hourly => (pricing.hourly_fare/60.0), :daily => pricing.daily_fare, :weekly => pricing.weekly_fare, :monthly => pricing.monthly_fare}
		
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

	def self.check_late(booking)
		#city_id=1
		data = {:hours => 0, :billed_hours => 0, :standard_hours => 0, :discounted_hours => 0, :estimate => 0, :discount => 0}
		if !booking.returned_at.blank? && booking.returned_at > (booking.ends + 30.minutes)
			#cargroup = self.cargroup
			# cargroup_id = booking.cargroup_id
			# #version = booking.version
			version = "v1"
			# city_id = booking.location.city_id
			pricing = Pricing.find_by(city_id: booking.location.city_id,cargroup_id: booking.cargroup_id,version: version)
			#rate = cargroup.hourly_fare
			rate = pricing.hourly.fare
			data[:hours] = (booking.returned_at.to_i - booking.ends.to_i)/3600
			data[:hours] += 1 if (booking.returned_at.to_i - booking.ends.to_i) > data[:hours]*3600
			data[:billed_hours] += data[:hours]
			min = 1
			wday = booking.ends.wday
			while min <= data[:hours]*60
				if min == ((min/60)*60)
					data[:estimate] += rate
					if [0,5,6].include?(wday)
						data[:standard_hours] += 1
					else
						data[:discounted_hours] += 1
						data[:discount] += rate*(CommonHelper::WEEKDAY_DISCOUNT/100.0)
					end
					wday = (booking.ends + min.minutes).wday
				end
				min += 1
			end
		end
		return data
	end
end
