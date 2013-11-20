class Utilization < ActiveRecord::Base

	def self.create_utiliz(booking,car_id)
		current_utilization = Utilization.new
		current_utilization.booking_id = booking.id
		current_utilization.car_id = car_id
		current_utilization.cargroup_id = booking.cargroup_id
		current_utilization.location_id = booking.location_id
		current_utilization.day = booking.starts.to_date
		current_utilization.billed_minutes = ((booking.ends-booking.starts)/60).to_f
		current_utilization.save
	end

end
