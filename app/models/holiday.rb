class Holiday < ActiveRecord::Base
	
	def self.list
		Rails.cache.fetch("holidays") do
			Holiday.find_by_sql("SELECT h.name, h.day, DAY(h.day) as d, MONTH(h.day) as m FROM holidays h WHERE h.repeat = 1 OR YEAR(h.day) = #{Time.today.year} ORDER BY m ASC, d ASC")
		end
	end
	
end
