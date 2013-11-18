class Booking < ActiveRecord::Base


	def self.select_car(booking)


		#find all the booked cars utlization for that day in increasing order
		#if any of the car have free slot for the curret time then select that car and create the utlization
		cars=Array.new

		start_day = booking[:starts].to_date
		end_day = booking[:ends].to_date

		while start_day <= end_day do

		cars +=  Utilization.find(:all,:conditions => ["location_id =? AND cargroup_id =? AND day =?"
			,booking[:location_id],booking[:cargroup_id],booking[:starts].to_date],:group => "car_id")
		
		start_day += 1.days

		end

		if !cars
			#select random car
			#add to utilization
			#update booking
		else
			#select car with minimum utlization
			#create utlization
			#update booking
		end






	end

end
