class Pricingv4
	
	BUFFER_TIME = 30
	CHARGE_CAP = 2500
	CHARGE_PERCENTAGE = 25
	CREDIT_PERCENTAGE = 50
	LATE_FEE = 300
	SECURITY = 5000
	SHORT_PERCENTAGE = 25
	START_BUFFER_TIME = 24
	MIN_HOURS = 4
	
	def initialize(booking)
		@booking = booking
		@pricing = booking.pricing
	end

	def cancel
		data = get_fare(@booking.starts, @booking.ends)
		if @booking.id.blank?
			data[:refund] = data[:total]
		else
			data[:refund] = @booking.refund_amount
		end
		if @booking.id.blank? || (!@booking.id.blank? && Time.now > (@booking.starts - START_BUFFER_TIME.hours) && !@booking.auto_cancel)
			data[:penalty] = (data[:refund]*(CHARGE_PERCENTAGE/100.0)).round
			data[:penalty] = CHARGE_CAP if data[:penalty] > CHARGE_CAP
		end
		data[:log] = true
		return data
	end
	
	def self.check(booking)
		self.new(booking).check
	end
	
	def check
		data = {}
		if @booking.status < 9
			if !@booking.returned_at.blank?
				if @booking.returned_at > (@booking.ends + BUFFER_TIME.minutes)
					# Late
					data = late
				elsif @booking.returned_at < (@booking.ends - BUFFER_TIME.minutes)
					# Early
					data = early
				end
			else
				if !@booking.starts_last.blank? && !@booking.ends_last.blank?
					if @booking.starts != @booking.starts_last || @booking.ends != @booking.ends_last
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
		if (@booking.end_km.to_i - @booking.start_km.to_i) > data[:kms]
			data[:kms_penalty] = ((@booking.end_km.to_i - @booking.start_km.to_i - data[:kms]) * data[:excess_kms]).round
		end
		return data
	end
	
	def early
		data = get_fare(@booking.starts, @booking.ends)
		tmp = get_fare(@booking.starts, @booking.returned_at)
		data[:log] = true if data[:hours] != tmp[:hours]
		if (data[:total] > tmp[:total])
			data[:refund] = data[:total] - tmp[:total]
			data[:penalty] = (data[:refund]*((100-CREDIT_PERCENTAGE)/100.0)).round
		end
		data = Pricingv4.subtract_hash(data,tmp)
		data[:kms] += tmp[:kms]
		return data
	end
	
	def late
		data = get_fare(@booking.starts, @booking.returned_at - BUFFER_TIME.minutes)
		tmp = get_fare(@booking.starts, @booking.ends)
		data[:log] = true if data[:hours] != tmp[:hours]
		data[:penalty] = ((data[:hours] - tmp[:hours])*LATE_FEE) if (data[:hours] > tmp[:hours])
		data = Pricingv4.subtract_hash(data,tmp)
		data[:kms] += tmp[:kms]
		return data
	end
	
	def mis(start_date, end_date)
		temp = {
			days: 0, standard_days: 0, discounted_days: 0, 
			hours: 0, standard_hours: 0, discounted_hours: 0
		}
		h = (end_date.to_i - start_date.to_i)/3600
		h += 1 if (end_date.to_i - start_date.to_i) > h*3600
		h = MIN_HOURS if h < MIN_HOURS
		
		d = h/24
		h = h - d*24
		temp[:days] = d
		temp[:hours] = h
		if d > 0
			if d >= 7
				temp[:discounted_days] = d
				temp[:discounted_hours] = h
				h = 0
			else
				(0..(d-1)).each do |i|
					wday = (start_date + i.days).wday
					if wday > 0 && wday < 5
						temp[:discounted_days] += 1
					else
						temp[:standard_days] += 1
					end
				end
			end
		end
		wday = (start_date + d.days).wday
		if wday > 0 && wday < 5
			temp[:discounted_hours] += h
		else
			temp[:standard_hours] += h
		end
		return temp
	end
	
	def normal
		return get_fare(@booking.starts, @booking.ends)
	end
	
	def reschedule
		data = get_fare(@booking.starts_last, @booking.ends_last)
		tmp = get_fare(@booking.starts, @booking.ends)
		if data[:hours] != tmp[:hours] || data[:total] != tmp[:total]
			data[:log] = true
			tmp[:log] = true
		end
		if tmp[:total] < data[:total]
			# Charges for late reschedule
			data[:refund] = data[:total] - tmp[:total]
			if @booking.id.blank? || (!@booking.id.blank? && Time.now > (@booking.starts_last - START_BUFFER_TIME.hours))
				data[:penalty] = (data[:refund]*(CHARGE_PERCENTAGE/100.0)).round
				data[:penalty] = CHARGE_CAP if data[:penalty] > CHARGE_CAP
			end
			data = Pricingv4.subtract_hash(data,tmp)
			data[:kms] = tmp[:kms]
		else
			tmp = Pricingv4.subtract_hash(tmp,data)
			tmp[:kms] += data[:kms]
			data = tmp
		end
		return data
	end
	
	private
	
	def get_fare(start_date, end_date)
		data = {
			total: 0, estimate: 0, discount: 0, bod_extra: 0,
			hours: 0, standard_hours: 0, discounted_hours: 0, bod_hours: 0,
			excess_kms: @pricing.excess_kms, kms: 0, log: false, 
			penalty: 0, refund: 0, kms_penalty: 0
		}
		
		h = (end_date.to_i - start_date.to_i)/3600
		h += 1 if (end_date.to_i - start_date.to_i) > h*3600
		data[:hours] = h
		
		h = MIN_HOURS if h < MIN_HOURS

		bod_fare = @pricing.hourly_bod_fare.to_i
		if (h/24) >= 7
			discounted_fare = ((@pricing.hourly_discounted_fare.to_i) * (1-(@pricing.weekly_percentage_discount.to_f/100))).to_i
			fare = ((@pricing.hourly_fare.to_i) * (1-(@pricing.weekly_percentage_discount.to_f/100))).to_i
		else
			discounted_fare = @pricing.hourly_discounted_fare.to_i
			fare = @pricing.hourly_fare
		end
		kms = @pricing.hourly_kms

		hour = 1
		wday = start_date.wday
		data[:kms] = (kms*h).round
		year = start_date.year
		
		promo_pricing = @booking.city.promo_pricing
		if promo_pricing
			blackout_days = []
		else
			blackout_days = Holiday.list(year)
		end

		while hour <= h
			data[:estimate] += fare
			if blackout_days.include?(start_date.advance(hours: (hour-1)).strftime("%m-%d"))
				data[:bod_hours] += 1
				data[:bod_extra] += (bod_fare - fare)
			elsif [0,5,6].include?(wday)
				data[:standard_hours] += 1
			else
				data[:discounted_hours] += 1
				data[:discount] += (fare - discounted_fare)
			end
			if year != start_date.advance(hours: hour).year
				year = start_date.advance(hours: hour).year
				blackout_days = Holiday.list(year)
			end
			wday = start_date.advance(hours: hour).wday
			hour += 1
		end
		data[:estimate] = data[:estimate].round
		data[:discount] = data[:discount].round
		data[:total] = data[:estimate] - data[:discount] + data[:bod_extra]
		return data
	end
	
	def self.subtract_hash(org,mod)
		mod.each do |k,v|
			org[k] -= v if v.is_a? Integer
		end
		return org
	end
	
end