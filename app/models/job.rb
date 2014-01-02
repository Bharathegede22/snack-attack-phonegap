class Job < ActiveRecord::Base
  
  def encoded_id
		CommonHelper.encode('job', self.id)
	end
	
  def h1
		return self.title
	end
	
	def link
		return "http://www.zoomcar.in/job/" + self.encoded_id
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
  	Job.find(:all, :conditions => "status = 1", :order => "department ASC, hire_type ASC, id DESC")
  end
  
end
