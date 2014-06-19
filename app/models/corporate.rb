class Corporate < ActiveRecord::Base

	def self.make_corporate_hash
		corporate_hash = {}
		Corporate.all.each do |record|
			corporate_hash[record.id.to_s] = record.name 
		end
		corporate_hash
	end

end