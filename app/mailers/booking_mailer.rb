class BookingMailer < ActionMailer::Base
  
  layout 'email'
  
  default from: "ZoomCar <help@zoomcar.in>", bcc: "support@zoomcar.in"
  
  def cancel(booking, charge)
		@booking = Booking.find(booking)
		@charge = charge
		@user = @booking.user
		mail(:to => @user.email, :subject => "You've cancelled a Zoom reservation.")
	end
	
	def change(booking, charge)
		@booking = Booking.find(booking)
		@charge = charge
		@user = @booking.user
		mail(:to => @user.email, :subject => "Your Zoom reservation details have been changed.")
	end
	
  def payment(booking)
		@booking = booking
		@user = @booking.user
		mail(:to => @user.email, :subject => "Review your Zoom reservation details.")
	end
	
end
