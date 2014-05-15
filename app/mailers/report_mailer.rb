class ReportMailer < ActionMailer::Base
  
  default from: "Zoomcar <noreply@zoomcar.in>"
  
  def exotel(error, phone, booking)
  	@error = error
  	@phone = phone
  	@booking = booking
  	mail to: "amit@zoomcar.in", subject: "[ZoomWeb] Exotel Error"
  end
  
  def review(review)
  	@review = review
  	@booking = @review.booking
  	mail to: "bhuvnesh@zoomcar.in", subject: "User Feedback"
  end
  
end
