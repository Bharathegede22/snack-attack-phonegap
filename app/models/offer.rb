class Offer < ActiveRecord::Base
	
	def self.active
		Rails.cache.fetch("offers") do
			Offer.find_by_sql("SELECT * FROM offers WHERE status = 1 AND visibility = 1")
		end
	end
	
end
