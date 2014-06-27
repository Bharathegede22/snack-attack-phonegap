class BookingMailer < ActionMailer::Base
  
  layout 'email'
  
  default from: "ZoomCar <help@zoomcar.in>"#, bcc: "support@zoomcar.in"
  
  def cancel(booking, charge)
		@booking = Booking.find_by_id booking
		@charge = Charge.find_by_id charge
		@user = @booking.user
		support_email = City.find(@booking.city_id).contact_email
		mail(:to => @user.email, :subject => "Your Zoom Reservation : #{@booking.confirmation_key}", bcc: support_email)
	end
	
	def change(booking, charge)
		@booking = Booking.find_by_id booking
		if !charge.nil?
			@charge = Charge.find_by_id charge
		else
			@charge = nil
		end
		@user = @booking.user
		support_email = City.find(@booking.city_id).contact_email
		mail(:to => @user.email, :subject => "Your Zoom Reservation : #{@booking.confirmation_key}", bcc: support_email)
	end
	
	def change_failed(booking)
		@booking = Booking.find_by_id booking
		support_email = City.find(@booking.city_id).contact_email
		mail(:to => support_email, :subject => "Booking extension failed because of no inventory.")
	end
	
	def license_update(user)
		@user = User.find_by_id user
		mail(:to => support_email, :subject => "License Update for: #{@user.email} ")
	end

  def payment(booking)
		@booking =Booking.find_by_id booking
		@user = @booking.user
		support_email = City.find(@booking.city_id).contact_email
		mail(:to => @user.email, :subject => "Your Zoom Reservation : #{@booking.confirmation_key}", bcc: support_email)
	end
	
end
