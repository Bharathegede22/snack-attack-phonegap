class BookingMailer < ActionMailer::Base
  
  layout 'email'
  
  default from: "Zoomcar <help@zoomcar.com>"
  
  def cancel(booking, total,deposit)
		@booking = Booking.find_by_id booking
		@total = total
		@deposit = deposit
		@user = @booking.user
		mail(:to => @user.email, :subject => "Your Zoomcar Reservation : #{@booking.confirmation_key}", bcc: @booking.city.contact_email)
	end
	
	def change(booking, total)
		@booking = Booking.find_by_id booking
		@total = total
		@user = @booking.user
		mail(:to => @user.email, :subject => "Your Zoomcar Reservation : #{@booking.confirmation_key}", bcc: @booking.city.contact_email)
	end
	
	def change_failed(booking)
		@booking = Booking.find_by_id booking
		mail(:to => @booking.city.contact_email, :subject => "Booking extension failed because of no inventory.")
	end
	
	def license_update(user)
		@user = User.find_by_id user
		mail(:to => 'support@zoomcar.com', :subject => "License Update for: #{@user.email} ")
	end

  def payment(booking)
		@booking =Booking.find_by_id booking
		@user = @booking.user
		mail(:to => @user.email, :subject => "Your Zoomcar Reservation : #{@booking.confirmation_key}", bcc: @booking.city.contact_email)
	end

	def kle_mail(booking)
		@booking = Booking.find_by_id booking
		mail(to: @booking.user.email, subject: "Zoomcar goes keyless! And so does your booking")
	end

	def welcome(user)
		@user = user
		mail(to: @user.email, subject: "Welcome To Zoomcar")
	end
	
end
