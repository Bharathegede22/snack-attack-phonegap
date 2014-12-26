class ReportMailer < ActionMailer::Base
  
  default from: "Zoomcar <noreply@zoomcar.com>"
  # layout 'report', only: [:referral]
  
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

  def referral(user)
    @user = user
    @city = !@user.city_id.nil? ? City.find(@user.city_id) : City.find(1)
    mail(to: @user.email, subject: "<full name of user who sent invite> wants to share the joy of self-drive with you. Sign up and earn ₹500 in credits!") do |format|
      format.html {render layout: false}
    end
  end
end
