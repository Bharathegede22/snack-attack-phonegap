class BookingMailer < ActionMailer::Base
  
  layout 'email'
  
  default from: "Zoomcar <help@zoomcar.com>"
  
  def cancel(booking, total,deposit)
		@booking = Booking.find_by_id booking
		@city = @booking.city_id rescue 1
		@total = total
		@deposit = deposit
		@user = @booking.user
		mail(:to => @user.email, :subject => "Your Zoomcar Reservation : #{@booking.confirmation_key}", bcc: @booking.city.contact_email)
	end
	
	def change(booking, total)
		@booking = Booking.find_by_id booking
		@city = @booking.city_id rescue 1
		@total = total
		@user = @booking.user
		mail(:to => @user.email, :subject => "Your Zoomcar Reservation : #{@booking.confirmation_key}", bcc: @booking.city.contact_email)
	end
	
	def change_failed(booking)
		@booking = Booking.find_by_id booking
		@city = @booking.city_id rescue 1
		mail(:to => @booking.city.contact_email, :subject => "Booking extension failed because of no inventory.")
	end
	
	def license_update(user)
		@user = User.find_by_id user
		@city = @user.city_id rescue 1
		mail(:to => 'support@zoomcar.com', :subject => "License Update for: #{@user.email} ")
	end

  def payment(booking)
		@booking =Booking.find_by_id booking
		@user = @booking.user
		@city = @booking.city_id rescue 1
		mail(:to => @user.email, :subject => "Your Zoomcar Reservation : #{@booking.confirmation_key}", bcc: @booking.city.contact_email)
	end

	def kle_mail(booking)
		@booking = Booking.find_by_id booking
		@city = @booking.city_id rescue 1
		mail(to: @booking.user.email, subject: "Zoomcar goes keyless! And so does your booking")
	end

	def welcome(user)
		@user = user
		@city = @user.city_id rescue 1
		mail(to: @user.email, subject: "Welcome To Zoomcar")
	end
	
end
