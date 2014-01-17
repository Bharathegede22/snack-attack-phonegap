class Location < ActiveRecord::Base
	
	def mapcontent
		text = "<b>" + self.shortname + "</b><br/>"
		text << "<b style='color:red;'>" + self.disclaimer + "</b><br/>" if !self.disclaimer.blank?
		text << "<table><tr><th>Car Type</th><th>Total</th></tr>"
		Cargroup.find_by_sql("SELECT cg.*, COUNT(DISTINCT c.id) AS total FROM cargroups cg 
			INNER JOIN cars c ON c.cargroup_id = cg.id 
			WHERE c.status > 0 AND c.location_id = #{self.id}
			GROUP BY cg.id 
			ORDER BY cg.priority ASC").each do |cg|
			text << "<tr><td>" + cg.shortname + "</td><td>" + cg.total.to_s + "</td></tr>" if cg.total > 0
		end
		text << "</table>"
		return text.html_safe
	end
	
	def shortname
		if self.status == 1
			return self.name.split(',').last
		else
			return self.name.split(',').last + " *"
		end
	end
	
	def self.live
		Location.find_by_sql("SELECT l.* FROM locations l 
			INNER JOIN cars c ON c.location_id = l.id 
			WHERE c.status > 0 AND l.status > 0 
			GROUP BY l.id
			ORDER BY id DESC")
	end
	
end
