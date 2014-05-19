class BookingMailer < ActionMailer::Base
  
  layout 'email'
  
  default from: "ZoomCar <help@zoomcar.in>", bcc: "support@zoomcar.in"
  
  def cancel(booking, charge)
		@booking = Booking.find_by_id booking
		@charge = Charge.find_by_id charge
		@user = @booking.user
		mail(:to => @user.email, :subject => "Your Zoom Reservation : #{@booking.confirmation_key}")
	end
	
	def change(booking, charge)
		@booking = Booking.find_by_id booking
		if !charge.nil?
			@charge = Charge.find_by_id charge
		else
			@charge = nil
		end
		@user = @booking.user
		mail(:to => @user.email, :subject => "Your Zoom Reservation : #{@booking.confirmation_key}")
	end
	
	def change_failed(booking)
		@booking = Booking.find_by_id booking
		mail(:to => 'support@zoomcar.in', :subject => "Booking extension failed because of no inventory.")
	end
	
	def license_update(user)
		@user = User.find_by_id user
		mail(:to => 'support@zoomcar.in', :subject => "License Update for: #{@user.email} ")
	end

  def payment(booking)
		@booking =Booking.find_by_id booking
		@user = @booking.user
		mail(:to => @user.email, :subject => "Your Zoom Reservation : #{@booking.confirmation_key}")
	end
	
end
