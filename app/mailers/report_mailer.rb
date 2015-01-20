class ReportMailer < ActionMailer::Base
  
  default from: "Zoomcar <noreply@zoomcar.com>"

  def exotel(error, phone, booking)
  	@error = error
  	@phone = phone
  	@booking = booking
  	mail to: "error@zoomcar.com", subject: "[ZoomWeb] Exotel Error"
  end
  
  def review(review)
  	@review = Review.find_by_id review
  	@booking = @review.booking
  	mail to: "feedback@zoomcar.com", subject: "User Feedback"
  end

end
