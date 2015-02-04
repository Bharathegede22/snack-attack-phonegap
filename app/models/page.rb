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

# == Schema Information
#
# Table name: pages
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text
#  active     :boolean          default(TRUE)
#  created_at :datetime
#  updated_at :datetime
#  city_id    :integer
#
# Indexes
#
#  index_pages_on_title  (title)
#
