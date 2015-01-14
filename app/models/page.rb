class Page < ActiveRecord::Base
	
	belongs_to :city

	def encoded_id
		CommonHelper.encode('page', self.id)
	end
	
	def link
		if self.city_id.blank?
			return "http://" + HOSTNAME + "/" + CommonHelper.escape(self.title.downcase) + "_" + self.encoded_id
		else
			return "http://" + HOSTNAME + "/" + CommonHelper.escape(self.city.name.downcase) + "/" + CommonHelper.escape(self.title.downcase) + "_" + self.encoded_id
		end
	end
	
end
