class Announcement < ActiveRecord::Base
	
	def self.active
		Rails.cache.fetch("announcements") do
			Announcement.find_by_sql("SELECT * FROM announcements WHERE active = 1 ORDER BY id DESC LIMIT 1")
  	end
  end
  
end

# == Schema Information
#
# Table name: announcements
#
#  id     :integer          not null, primary key
#  note   :string(255)
#  active :boolean
#
