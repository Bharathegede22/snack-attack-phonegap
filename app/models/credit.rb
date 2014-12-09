class Credit < ActiveRecord::Base
	
	belongs_to :creditable, :polymorphic => true
	belongs_to :user
	
	after_create :after_create_tasks
	
	default_scope where("(status = 1)")
	SOURCE_NAME = {1 => "Booking", 2 => "Early Return", 3 => "Call center", 4 => "Refund more than cash paid", 5 => "Promo Code", 6 => "Sign up", 7 => "Referral", 8 => "Checkout Refresh", 9 => "Others"}
	SOURCE_NAME_INVERT = SOURCE_NAME.invert
	def self.use_credits(booking, amount)
		payment = Payment.new
		payment.booking_id = booking.id
		payment.status = 1
		payment.through = 'credits'
		payment.amount = amount
		payment.save!

		credit = Credit.new
		credit.user_id = booking.user_id
    credit.booking_key = booking.confirmation_key.upcase
		credit.creditable_type = 'Booking'
		credit.amount = amount
		credit.action = false
		credit.source_name = Credit::SOURCE_NAME_INVERT["Booking"]
		credit.status = 1
		credit.creditable_id = booking.id
		credit.save!
  end

  def history_description
  	return "Booking Fee" if !self.action && self.booking_key.present?
  	self.action ? "Credits Added" : "Credits Correction"
  end

	protected

	def after_create_tasks
		user.update_credits
	end
	
end

# == Schema Information
#
# Table name: credits
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  booking_key     :string(255)
#  promo_code      :text
#  updated_by      :integer
#  creditable_type :string(255)
#  amount          :integer
#  action          :boolean          default(TRUE)
#  created_at      :datetime
#  updated_at      :datetime
#  status          :boolean          default(TRUE)
#  note            :string(255)
#  creditable_id   :integer
#  source_name     :integer
#
