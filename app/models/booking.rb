class Booking < ActiveRecord::Base


	def self.select_car(booking)

		#find all the booked cars utlization for that day in increasing order
		#single day booking first

		#do this for the booking starts with in next one hour


		start_day = booking.starts.to_date
		end_day = booking.ends.to_date

		cars = Utilization.find(:all,:conditions => ["location_id =? AND cargroup_id =? AND day =?",
			   booking.location_id,booking.cargroup_id,start_day],:group => "car_id,day")
		
			random_car=Car.find(:all , :conditions => ["cargroup_id =?",booking.cargroup_id]).first
			current_booking=Booking.find(booking.id)
			current_booking.update(car_id: random_car.id)
			current_utilization=Utilization.new
			current_utilization.booking_id=	booking.id
			current_utilization.car_id=random_car.id
			current_utilization.cargroup_id=booking.cargroup_id
			current_utilization.location_id=booking.location_id
			current_utilization.day=booking.starts.to_date
			current_utilization.billed_minutes= ((booking.ends-booking.starts)*24*60).to_f
			current_utilization.save



	end

end
