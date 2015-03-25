class Job < ActiveRecord::Base
  
  def encoded_id
		CommonHelper.encode('job', self.id)
	end
	
  def h1
		return self.title
	end
	
	def link
		return "http://" + HOSTNAME + "/job/" + self.encoded_id
	end
	
	def meta_description
		return self.title + " - " + CommonHelper::DEPARTMENT[self.department][0] + " @ Zoomcar Bangalore | " + self.encoded_id
	end
	
	def meta_keywords
		@meta_keywords = "zoomcar job"
	end
	
	def meta_title
		return self.title + " - " + CommonHelper::DEPARTMENT[self.department][0] + " Careers @ Zoomcar | " + self.encoded_id
	end
	
  def self.live
  	Rails.cache.fetch("jobs") do
  		Job.find_by_sql("SELECT * FROM jobs WHERE status = 1 ORDER BY department ASC, hire_type ASC, id DESC")
  	end
  end
  
end

# == Schema Information
#
# Table name: jobs
#
#  id              :integer          not null, primary key
#  title           :string(255)
#  description     :text
#  hire_type       :integer
#  min_workex      :integer
#  relevant_workex :integer
#  department      :integer
#  status          :boolean
#  created_at      :datetime
#  updated_at      :datetime
#
