class Pricingv3
	
	BUFFER_TIME = 30
	CHARGE_CAP = 2500
	CHARGE_PERCENTAGE = 25
	CREDIT_PERCENTAGE = 50
	LATE_FEE = 300
	SECURITY = 5000
	SHORT_PERCENTAGE = 25
	START_BUFFER_TIME = 24
	MIN_HOURS = 4
	
	def self.cancel
		data = get_fare(@@booking.starts, @@booking.ends)
		if @@booking.id.blank?
			data[:refund] = data[:total]
		else
			data[:refund] = @@booking.refund_amount
		end
		if @@booking.id.blank? || (!@@booking.id.blank? && Time.now > (@@booking.starts - START_BUFFER_TIME.hours))
			data[:penalty] = (data[:refund]*(CHARGE_PERCENTAGE/100.0)).round
			data[:penalty] = CHARGE_CAP if data[:penalty] > CHARGE_CAP
		end
		data[:log] = true
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
		data[:log] = true if data[:hours] != tmp[:hours]
		if (data[:total] > tmp[:total])
			data[:refund] = data[:total] - tmp[:total]
			data[:penalty] = (data[:refund]*((100-CREDIT_PERCENTAGE)/100.0)).round
		end
		data = substract_hash(data,tmp)
		data[:kms] += tmp[:kms]
		return data
	end
	
	def self.late
		data = get_fare(@@booking.starts, @@booking.returned_at)
		tmp = get_fare(@@booking.starts, @@booking.ends)
		data[:log] = true if data[:hours] != tmp[:hours]
		data[:penalty] = ((data[:hours] - tmp[:hours])*LATE_FEE) if (data[:hours] > tmp[:hours])
		data = substract_hash(data,tmp)
		data[:kms] += tmp[:kms]
		return data
	end
	
	def self.normal
		return get_fare(@@booking.starts, @@booking.ends)
	end
	
	def self.reschedule
		data = get_fare(@@booking.starts_last, @@booking.ends_last)
		tmp = get_fare(@@booking.starts, @@booking.ends)
		if data[:hours] != tmp[:hours] || data[:total] != tmp[:total]
			data[:log] = true
			tmp[:log] = true
		end
		if tmp[:total] < data[:total]
			# Charges for late reschedule
			data[:refund] = data[:total] - tmp[:total]
			if @@booking.id.blank? || (!@@booking.id.blank? && Time.now > (@@booking.starts_last - START_BUFFER_TIME.hours))
				data[:penalty] = (data[:refund]*(CHARGE_PERCENTAGE/100.0)).round
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
	
	def self.get_fare(start_date, end_date)
		data = {
			total: 0, estimate: 0, discount: 0, 
			hours: 0, standard_hours: 0, discounted_hours: 0, 
			excess_kms: @@pricing.excess_kms, kms: 0, log: false, 
			penalty: 0, refund: 0, kms_penalty: 0
		}
		
		h = (end_date.to_i - start_date.to_i)/3600
		h += 1 if (end_date.to_i - start_date.to_i) > h*3600
		h = MIN_HOURS if h < MIN_HOURS
		
		discounted_fare = 0
		if (h/24) >= 7
			fare = @@pricing.weekly_fare.to_f/(7*24)
			kms = @@pricing.weekly_kms.to_f/(7*24)
		else
			discounted_fare = @@pricing.hourly_discounted_fare.to_i
			fare = @@pricing.hourly_fare
			kms = @@pricing.hourly_kms
		end
		
		data[:hours] = h
		hour = 1
		wday = start_date.wday
		data[:kms] = (kms*data[:hours]).round
		
		while hour <= h
			data[:estimate] += fare
			if discounted_fare == 0 || [0,5,6].include?(wday)
				data[:standard_hours] += 1
			else
				data[:discounted_hours] += 1
				data[:discount] += (fare - discounted_fare)
			end
			wday = (start_date + hour.hours).wday
			hour += 1
		end
		data[:estimate] = data[:estimate].round
		data[:discount] = data[:discount].round
		data[:total] = data[:estimate] - data[:discount]
		return data
	end
	
	def self.substract_hash(org,mod)
		mod.each do |k,v|
			org[k] -= v if v.is_a? Integer
		end
		return org
	end
	
end
