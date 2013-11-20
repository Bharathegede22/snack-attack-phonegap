class Booking < ActiveRecord::Base


	def self.select_car(booking)
		
 		start_day = booking.starts.to_date
		end_day = booking.ends.to_date	
		present = true	

		cars =  Utilization.where("cargroup_id =? AND location_id =? AND day >=? AND day <= ? ",booking.cargroup_id,booking.location_id,
			    start_day,end_day).group(:car_id).sum(:billed_minutes)

		if cars.empty?		
			random_car=Car.find(:all , :conditions => ["cargroup_id =?",booking.cargroup_id]).first			
			current_booking = Booking.find(booking.id)
			current_booking.update(car_id: random_car.id)
			Utilization.create_utiliz(booking,random_car.id)
		else
			cars.sort_by{ |k,v| -v }
			cars.each do |car_id,utilization|
				if Booking.check_booking(booking.starts,booking.ends,booking.cargroup_id,booking.location_id,car_id)
					current_booking = Booking.find(booking.id)
					current_booking.update(car_id: car_id)
					Utilization.create_utiliz(booking,car_id)
					present = false					
					break	
				end
			end

			if present
				c=Car.find(:all,:conditions => ["cargroup_id =? AND location_id =? ",booking.cargroup_id,booking.location_id])
				c.each do |car|
					if !cars.has_key?(car.id)
						current_booking = Booking.find(booking.id)
						current_booking.update(car_id: car.id)
						Utilization.create_utiliz(booking,car.id)
						break
					end
				end
			end

		end
	end


	def self.check_booking(starts,ends,cargroup_id,location_id,car_id)
		check = Booking.find(:all,:conditions => ["starts =? AND ends =? AND cargroup_id =? AND car_id =? AND
			  location_id =?",starts,ends,cargroup_id,car_id,location_id])
		return check.empty? ? true : false
	end
end

