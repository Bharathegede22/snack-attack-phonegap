class Time
# Time#round already exists with different meaning in Ruby 1.9
	def round_off(seconds = 900)
		Time.at((self.to_f / seconds).round * seconds)
	end

	def floor(seconds = 900)
		Time.at((self.to_f / seconds).floor * seconds)
	end

	def ceil(seconds = 900)
		Time.at((self.to_f / seconds).ceil * seconds)
	end

	def slot
		(self - Time.parse("2013-01-01")).to_i/900
	end

	def self.parse_slot(slot)
		Time.parse("2013-01-01") + (slot.to_i*15).minutes
	end

	def leap_yday
		if to_date.leap?
			if yday<60
				yday
			else
				yday-1
			end
		else
			yday
		end
	end
end

class Date
	def leap_yday
		if leap?
			if yday<60
				yday
			else
				yday-1
			end
		else
			yday
		end
	end
end