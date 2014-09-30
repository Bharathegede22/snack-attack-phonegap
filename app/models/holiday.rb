class Holiday < ActiveRecord::Base
	
	def self.list
		Rails.cache.fetch("holidays") do
			Holiday.find_by_sql("SELECT h.name, h.day, DAY(h.day) as d, MONTH(h.day) as m FROM holidays h WHERE h.repeat = 1 OR YEAR(h.day) = #{Time.today.year} ORDER BY m ASC, d ASC")
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
