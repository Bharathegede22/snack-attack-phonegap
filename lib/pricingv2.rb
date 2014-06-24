class Pricingv2
	
	BUFFER_TIME = 30
	CHARGE_CAP = 2500
	CHARGE_PERCENTAGE = 25
	CREDIT_PERCENTAGE = 50
	LATE_FEE = 300
	SECURITY = 5000
	START_BUFFER_TIME = 24
	WEEKDAY_DISCOUNT = 40
	
	def self.cancel
		data = get(@@booking.starts, @@booking.ends, @@booking.pricing_mode)
		total = 0
		if Time.now > (@@booking.starts - START_BUFFER_TIME.hours)
			@booking.charges.each do |c|
				if !c.activity.include?('charge')
					if c.refund > 0
						total -= c.amount
					else
						total += c.amount
					end
				end
			end
			if ((CHARGE_PERCENTAGE/100.0)*total).round > CHARGE_CAP
				total = CHARGE_CAP
			else
				total = (total*(CHARGE_PERCENTAGE/100.0)).round
			end
		end
		data[:penalty] = total
		data[:refund] = data[:total]
		return data
	end
	
	def self.check(booking, action=nil)
		cargroup = booking.cargroup
		@@pricing = cargroup.active_pricing(booking.city_id)
		@@booking = booking
		
		if !action.blank?
			return case action
			when 'cancel'				then cancel
			when 'early' 				then early
			when 'late' 				then late
			when 'new' 					then get(@@booking.starts, @@booking.ends, @@booking.pricing_mode)
			when 'reschedule'		then reschedule
		else
			if booking.status < 9 && booking.returned_at_changed?
				if booking.returned_at > (booking.ends + BUFFER_TIME.minutes)
					return late
				elsif booking.returned_at < (booking.ends - BUFFER_TIME.minutes)
					return early
				end
			else
			end
		end
	end
	
	def self.early
		data = {total: 0, estimate: 0, normal_discount: 0, offer_discount: 0, total_hours: 0, normal_hours: 0, discounted_hours: 0, kms: 0, penalty: 0, credits: 0, refund: 0}
		data = get(@@booking.starts, @@booking.ends, @@booking.pricing_mode)
		tmp = get(@@booking.starts, @@booking.returned_at, @@booking.pricing_mode)
		data[:credits] = ((data[:total] - tmp[:total])*(CREDIT_PERCENTAGE/100.0)) if (data[:total] > tmp[:total])
		data -= tmp
		return data
	end
	
	def self.late
		data = {total: 0, estimate: 0, normal_discount: 0, offer_discount: 0, total_hours: 0, normal_hours: 0, discounted_hours: 0, kms: 0, penalty: 0, credits: 0, refund: 0}
		data = get(@@booking.starts, @@booking.returned_at, @@booking.pricing_mode)
		tmp = get(@@booking.starts, @@booking.ends, @@booking.pricing_mode)
		data[:penalty] = ((data[:total_hours] - tmp[:total_hours])*LATE_FEE) if (data[:total_hours] > tmp[:total_hours])
		data -= tmp
		return data
	end
	
	def self.reschedule(action=nil)
		data = {total: 0, estimate: 0, normal_discount: 0, offer_discount: 0, total_hours: 0, normal_hours: 0, discounted_hours: 0, kms: 0, penalty: 0, credits: 0, refund: 0}
		data = get(@@booking.starts_was, @@booking.ends_was, @@booking.pricing_mode_was)
		tmp = get(@@booking.starts, @@booking.ends, @@booking.pricing_mode)
		
		if tmp[:total] < data[:total]
			# Charges for late reschedule
			if (Time.now > (@@booking.starts_was - START_BUFFER_TIME.hours))
				if @@booking.downgraded?
					data[:penalty] = (data[:total]*(CHARGE_PERCENTAGE/100.0)).round
				else
					data[:penalty] = ((data[:total] - tmp[:total])*(CHARGE_PERCENTAGE/100.0)).round
				end
				data[:penalty] = CHARGE_CAP if data[:penalty] > CHARGE_CAP
			end
			data -= tmp
			data[:refund] = data[:total]
			return data
		else
			tmp -= data
			data = tmp
		end
		return data
	end
	
	def self.shorten
		data = {total: 0, estimate: 0, normal_discount: 0, offer_discount: 0, total_hours: 0, normal_hours: 0, discounted_hours: 0, kms: 0, penalty: 0, credits: 0, refund: 0}
		data = get(@@booking.starts, @@booking.ends_was, @@booking.pricing_mode_was)
		tmp = get(@@booking.starts, @@booking.ends, @@booking.pricing_mode)
		if @@booking.downgrade?
			# Cancel Booking
			data[:penalty] = (data[:total]*(CHARGE_PERCENTAGE/100.0)).round
			data[:penalty] = CHARGE_CAP if data[:penalty] > CHARGE_CAP
			data[:refund] = (data[:total] - tmp[:total]) - data[:penalty]
			
		elsif data[:total] > tmp[:total]
			data[:penalty] = ((data[:total] - tmp[:total])*(CHARGE_PERCENTAGE/100.0)).round
			data[:penalty] = CHARGE_CAP if data[:penalty] > CHARGE_CAP
			data[:refund] = (data[:total] - tmp[:total]) - data[:penalty]
			data -= tmp
		end
		return data
	end
	
	private
	
	def self.get(start_date, end_date, mode)
		data = {total: 0, estimate: 0, normal_discount: 0, offer_discount: 0, total_hours: 0, normal_hours: 0, discounted_hours: 0, kms: 0, penalty: 0, credits: 0, refund: 0}
		
		h = (end_date.to_i - start_date.to_i)/3600
		h += 1 if (end_date.to_i - start_date.to_i) > h*3600
		
		data[:total_hours] = h
		min = 0
		discount = 0
		wday = start_date.wday
		
		case mode
		when 'h'
			fare = @@pricing.hourly_fare
			kms = @@pricing.hourly_kms
			discount = WEEKDAY_DISCOUNT
		when 'w'
			fare = @@pricing.weekly_fare.to_f/(7*24)
			kms = @@pricing.weekly_kms.to_f/(7*24)
		when 'm'
			fare = @@pricing.monthly_fare.to_f/(4*7*24)
			kms = @@pricing.monthly_kms.to_f/(4*7*24)
		end
		
		while min <= (h*60)
			if min == ((min/60)*60)
				data[:estimate] += fare
				data[:kms] += kms
				if discount == 0 || [0,1,6].include?(wday)
					data[:normal_hours] += 1
				else
					data[:discounted_hours] += 1
					data[:normal_discount] += (fare*discount)
				end
				wday = (start_date + min.minutes).wday
			end
			min += 1
		end
		data[:estimate] = data[:estimate].round
		data[:discount] = data[:discount].round
		data[:total] = data[:estimate] - data[:discount]
		return data
	end
	
end
