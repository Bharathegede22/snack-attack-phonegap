class Holiday < ActiveRecord::Base
	require "#{Rails.root}/lib/datetime_helper.rb"
	scope :blackout_holidays, -> {all}
	class << self
		def repeating_bod(start_date, end_date)
			blackout_holidays.where(repeat: true).select do |holiday|
				#TODO check laep year; see datetime_helper.rb
				case end_date.year-start_date.year
				when 0
					(start_date.leap_yday..end_date.leap_yday).include?(holiday.day.leap_yday)
				when 1
					(start_date.leap_yday..365).include?(holiday.day.leap_yday) || (1..start_date.leap_yday).include?(holiday.day.leap_yday)
				else
					true
				end
			end
		end

		def non_repeating_bod(start_date, end_date)
			blackout_holidays.where("holidays.repeat=? AND day<=? AND day>=?", false, end_date, start_date) 
		end

		def blackout_days(start_date, end_date)
			(repeating_bod(start_date, end_date) | non_repeating_bod(start_date, end_date))
		end
	
		def list
			Rails.cache.fetch("holidays") do
				Holiday.find_by_sql("SELECT h.name, h.day, DAY(h.day) as d, MONTH(h.day) as m FROM holidays h WHERE h.repeat = 1 OR YEAR(h.day) = #{Time.today.year} ORDER BY m ASC, d ASC")
			end
		end
	end
end

# == Schema Information
#
# Table name: holidays
#
#  id       :integer          not null, primary key
#  name     :string(255)
#  day      :date
#  internal :boolean          default(FALSE)
#  repeat   :boolean          default(FALSE)
#
# Indexes
#
#  index_holidays_on_repeat  (repeat)
#
