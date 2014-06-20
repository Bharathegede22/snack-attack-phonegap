class Corporate < ActiveRecord::Base
	
	has_many :bookings
	
	def self.live
		Rails.cache.fetch("corporates") do
			Corporate.find_by_sql("SELECT * FROM corporates WHERE active = 1 ORDER BY name ASC")
		end
	end
	
	def self.live_hash
		corporate_hash = {}
		Corporate.live.each do |record|
			corporate_hash[record.id.to_s] = record.name 
		end
		return corporate_hash
	end

end
