class BookingMailer < ActionMailer::Base
  
  layout 'email'
  
  default from: "ZoomCar <help@zoomcar.in>"#, bcc: "support@zoomcar.in"
  
  def cancel(booking, total)
		@booking = Booking.find_by_id booking
		@total = total
		@user = @booking.user
		mail(:to => @user.email, :subject => "Your Zoom Reservation : #{@booking.confirmation_key}", bcc: @booking.city.contact_email)
	end
	
	def change(booking, total)
		@booking = Booking.find_by_id booking
		@total = total
		@user = @booking.user
		mail(:to => @user.email, :subject => "Your Zoom Reservation : #{@booking.confirmation_key}", bcc: @booking.city.contact_email)
	end
	
	def change_failed(booking)
		@booking = Booking.find_by_id booking
		mail(:to => @booking.city.contact_email, :subject => "Booking extension failed because of no inventory.")
	end
	
	def license_update(user)
		@user = User.find_by_id user
		mail(:to => 'support@zoomcar.in', :subject => "License Update for: #{@user.email} ")
	end

  def payment(booking)
		@booking =Booking.find_by_id booking
		@user = @booking.user
		mail(:to => @user.email, :subject => "Your Zoom Reservation : #{@booking.confirmation_key}", bcc: @booking.city.contact_email)
	end
	
end
