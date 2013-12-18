class Booking < ActiveRecord::Base

	belongs_to :car
	belongs_to :cargroup
	belongs_to :location
	belongs_to :user
	
	has_many	:charges, :inverse_of => :booking, dependent: :destroy
	has_many	:payments, :inverse_of => :booking, dependent: :destroy
	has_many	:refunds, :inverse_of => :booking, dependent: :destroy
	has_many	:confirmed_payments, -> { where "status = 1" }, class_name: "Payment"
	has_many	:confirmed_refunds, -> { where "status = 1" }, class_name: "Refund"
	has_many	:reviews, :inverse_of => :booking, dependent: :destroy
	has_many	:utilizations, -> {where "minutes > 0"}, dependent: :destroy
	
	def check_payment
		total = self.outstanding
		if total > 0
			payment = Payment.find(:first, :conditions => ["booking_id = ? AND through = ? AND amount = ? AND status = 0", self.id, 'payu', total])
			payment = Payment.create!(booking_id: self.id, through: 'payu', amount: total) if !payment
		else
			payment = nil
		end
		return payment
	end
	
	def encoded_id
		CommonHelper.encode('booking', self.id)
	end
	
	def outstanding
		total = 0
		self.charges.each do |c|
			if c.activity != 'early_return_refund'
				if c.refund > 0
					total -= c.amount
				else
					total += c.amount
				end
			end
		end
		self.confirmed_payments.each do |p|
			total -= p.amount
		end
		self.confirmed_refunds.each do |r|
			total -= r.amount if r.through != 'early_return_credits'
		end		
		return total.to_i
	end
	
	def status?
		if self.status > 5
			return 'cancelled'
		else
			if self.starts <= Time.zone.now && self.ends >= Time.zone.now
				return 'live'
			elsif self.starts > Time.zone.now
				return 'future'
			elsif self.ends < Time.zone.now
				return 'completed'
			end
		end
	end
	
	def self.select_car(booking)
		
 		start_day = booking.starts.to_date
		end_day = booking.ends.to_date	
		present = true	

		cars =  Utilization.where("cargroup_id =? AND location_id =? AND day >=? AND day <= ? ",booking.cargroup_id,booking.location_id,
			    start_day,end_day).group(:car_id).sum(:billed_minutes)


		#if there is not utlization with given day,cargroup,location then select a random car
		if cars.empty?		

			random_car=Car.find(:all , :conditions => ["cargroup_id =?",booking.cargroup_id]).first			
			current_booking = Booking.find(booking.id)
			current_booking.update(car_id: random_car.id)
			Utilization.create_utiliz(booking,random_car.id)

		else

			#get the utlization for all booking with day,cargroup and allot the car with mxm utlization
			cars.sort_by { |k,v| -v }

			cars.each do |car_id,utilization|

				if Booking.check_booking(booking.starts,booking.ends,booking.cargroup_id,booking.location_id,car_id)
					current_booking = Booking.find(booking.id)
					current_booking.update(car_id: car_id)
					Utilization.create_utiliz(booking,car_id)
					present = false					
					break	

				end
			end


			#if already used car is not available then select a fresh  car
			if present
				c = Car.find(:all,:conditions => ["cargroup_id =? AND location_id =? ",booking.cargroup_id,
					          booking.location_id])

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
			  location_id = ?",starts,ends,cargroup_id,car_id,location_id])

		return check.empty? ? true : false
	end
end
