class Holiday < ActiveRecord::Base
	
	require "#{Rails.root}/lib/datetime_helper.rb"
	
	scope :blackout_holidays, -> {all}
	
	class << self
		def repeating_bod(start_date, end_date)
			blackout_holidays.where(repeat: true).to_a.select do |holiday|
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
			blackout_holidays.where("holidays.repeat=? AND day<=? AND day>=?", false, end_date, start_date).to_a
		end

		def blackout_days(start_date, end_date)
			(repeating_bod(start_date, end_date) | non_repeating_bod(start_date, end_date))
		end
	
		def list(year)
			Rails.cache.fetch("holidays-#{year}") do
				tmp = []
				blackout_days(Date.strptime("01-01-#{year}", '%d-%m-%Y'), Date.strptime("31-12-#{year}", '%d-%m-%Y')).each do |h|
					tmp << h.day.strftime("%m-%d")
				end
				tmp.sort
			end
		end

		def active
			year = Time.now.year
			Rails.cache.fetch("holidays-active-#{year}") do
				tmp = []
				blackout_days(Date.strptime("01-01-#{year-1}", '%d-%m-%Y'), Date.strptime("31-12-#{year+1}", '%d-%m-%Y')).each do |h|
					tmp << [h.day.strftime("%Y-%m-%d"), h]
				end
				tmp.sort.collect {|h| h[1]}
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
