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
	
	def change_failed(booking)
		@booking = booking
		mail(:to => 'support@zoomcar.in', :subject => "Booking extension failed because of no inventory.")
	end
	
  def payment(booking)
		@booking = booking
		@user = @booking.user
		@summary = Offer.where(["promo_code = '#{@booking.promo}'"])[0].summary
		mail(:to => @user.email, :subject => "Review your Zoom reservation details.")
	end
	
end
