class Pricingv1
	
	BUFFER_TIME = 30
	CHARGE_CAP = 2000
	CHARGE_PERCENTAGE = 25
	CREDIT_PERCENTAGE = 25
	SHORT_PERCENTAGE = 50
	START_BUFFER_TIME = 24
	WEEKDAY_DISCOUNT = 40
	
	def self.cancel
		data = get_fare(@@booking.starts, @@booking.ends)
		if @@booking.id.blank?
			data[:refund] = data[:total]
		else
			data[:refund] = @@booking.refund_amount
		end
		if @@booking.id.blank? || (!@@booking.id.blank? && Time.now > (@@booking.starts - START_BUFFER_TIME.hours))
			data[:penalty] = (data[:refund]*(CHARGE_PERCENTAGE/100.0)).round
			data[:log] = true
		end
		data[:penalty] = CHARGE_CAP if data[:penalty] > CHARGE_CAP
		return data
	end
	
	def self.check(booking)
		@@booking = booking
		@@pricing = booking.pricing
		data = {}
		if @@booking.status < 9
			if !@@booking.returned_at.blank?
				if @@booking.returned_at > (@@booking.ends + BUFFER_TIME.minutes)
					# Late
					data = late
				elsif @@booking.returned_at < (@@booking.ends - BUFFER_TIME.minutes)
					# Early
					data = early
				end
			else
				if !@@booking.starts_last.blank? && !@@booking.ends_last.blank?
					if @@booking.starts != @@booking.starts_last || @@booking.ends != @@booking.ends_last
						# Reshceduled
						data = reschedule
					end
				end
			end
		else
			# Cancellation
			data = cancel
		end
		# No change
		data = normal if data.blank?
		
		# Excess Kms
		if (@@booking.end_km.to_i - @@booking.start_km.to_i) > data[:kms]
			data[:kms_penalty] = ((@@booking.end_km.to_i - @@booking.start_km.to_i - data[:kms]) * data[:excess_kms]).round
		end
		return data
	end
	
	def self.early
		data = get_fare(@@booking.starts, @@booking.ends)
		tmp = get_fare(@@booking.starts, @@booking.returned_at)
		if (data[:total] > tmp[:total])
			data[:refund] = data[:total] - tmp[:total]
			data[:penalty] = (data[:refund]*((100-CREDIT_PERCENTAGE)/100.0)).round
		end
		data[:log] = true
		data = substract_hash(data,tmp)
		data[:kms] += tmp[:kms]
		return data
	end
	
	def self.late
		data = get_hash
		tmp = get_fare(@@booking.starts, @@booking.returned_at)
		data[:hours] = (@@booking.returned_at.to_i - @@booking.ends.to_i)/3600
		data[:hours] += 1 if (@@booking.returned_at.to_i - @@booking.ends.to_i) > data[:hours]*3600
		data[:billed_hours] += data[:hours]
		min = 1
		wday = @@booking.ends.wday
		while min <= data[:hours]*60
			if min == ((min/60)*60)
				data[:estimate] += @@pricing.hourly_fare
				if [0,5,6].include?(wday)
					data[:standard_hours] += 1
				else
					data[:discounted_hours] += 1
					data[:discount] += @@pricing.hourly_fare*(WEEKDAY_DISCOUNT/100.0)
				end
				wday = (@@booking.ends + min.minutes).wday
			end
			min += 1
		end
		data[:estimate] = data[:estimate].round
		data[:discount] = data[:discount].round
		data[:total] = data[:estimate] - data[:discount]
		data[:kms] = tmp[:kms]
		data[:log] = true
		return data
	end
	
	def self.normal
		return get_fare(@@booking.starts, @@booking.ends)
	end
	
	def self.reschedule
		data = get_fare(@@booking.starts_last, @@booking.ends_last)
		tmp = get_fare(@@booking.starts, @@booking.ends)
		data[:log] = true
		
		if tmp[:total] < data[:total]
			# Charges for late reschedule
			data[:refund] = data[:total] - tmp[:total]
			if @@booking.id.blank? || (!@@booking.id.blank? && Time.now > (@@booking.starts_last - START_BUFFER_TIME.hours))
				data[:penalty] = (data[:refund]*(SHORT_PERCENTAGE/100.0)).round
				data[:penalty] = CHARGE_CAP if data[:penalty] > CHARGE_CAP
			end
			data = substract_hash(data,tmp)
			data[:kms] = tmp[:kms]
		else
			tmp = substract_hash(tmp,data)
			tmp[:kms] += data[:kms]
			data = tmp
		end
		return data
	end
	
	private
	
	def self.get_hash
		return {
			total: 0, estimate: 0, discount: 0, 
			hours: 0, billed_hours: 0, standard_hours: 0, discounted_hours: 0, 
			days: 0, standard_days: 0, discounted_days: 0, 
			excess_kms: @@pricing.excess_kms, kms: 0, log: false, 
			penalty: 0, refund: 0, kms_penalty: 0
		}
	end
	
	def self.get_fare(start_date, end_date)
		temp = get_hash
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
				temp[:estimate] = ((@@pricing.monthly_fare/(28*24.0))*h).round
				temp[:kms] = ((@@pricing.monthly_kms/(28*24.0))*h).round
				return temp
			elsif d >= 7
				# Weekly
				h = d*24 + h
				temp[:estimate] = ((@@pricing.weekly_fare/(7*24.0))*h).round
				temp[:kms] = ((@@pricing.weekly_kms/(7*24.0))*h).round
				return temp
			else
				# Daily Fair
				(0..(d-1)).each do |i|
					wday = (start_date + i.days).wday
					temp[:estimate] += @@pricing.daily_fare
					temp[:kms] += @@pricing.daily_kms
					if wday > 0 && wday < 5
						temp[:discount] += @@pricing.daily_fare*(WEEKDAY_DISCOUNT/100.0)
						temp[:discounted_days] += 1
					else
						temp[:standard_days] += 1
					end
				end
			end
		end
		# Hourly Fair
		wday = (start_date + d.days).wday
		if h <= 10
			tmp = @@pricing.hourly_fare*h
		else
			tmp = @@pricing.daily_fare
		end
		temp[:estimate] += tmp
		if wday > 0 && wday < 5
			temp[:discount] += tmp*(WEEKDAY_DISCOUNT/100.0)
			temp[:discounted_hours] += h
		else
			temp[:standard_hours] += h
		end
		temp[:kms] += ((@@pricing.hourly_kms*h) < @@pricing.daily_kms) ? (@@pricing.hourly_kms*h) : @@pricing.daily_kms
		temp[:estimate] = temp[:estimate].round
		temp[:discount] = temp[:discount].round
		temp[:kms] = temp[:kms].round
		temp[:total] = temp[:estimate] - temp[:discount]
		return temp
	end
	
	def self.substract_hash(org,mod)
		mod.each do |k,v|
			org[k] -= v if v.is_a? Integer
		end
		return org
	end
	
end
