class Credit < ActiveRecord::Base
	
	belongs_to :creditable, :polymorphic => true
	after_create :after_create_tasks
	belongs_to :user
	
	default_scope where("(status = 1)")

	def self.use_credits(booking)
		
		payment = Payment.new
		payment.booking_id = booking.id
		payment.status = 1
		payment.through = 'credits'
		payment.amount = [booking.outstanding, booking.user.total_credits.to_f].min
		payment.save!

		credit = Credit.new
		credit.user_id = booking.user_id
		credit.creditable_type = 'booking'
		credit.amount =payment.amount
		credit.action = 'debit'
		credit.source_name = 'booking'
		credit.status = 1
		credit.creditable_id = booking.id
		credit.save!

		#current_user.update_credits
	end

	def after_create_tasks
		user.update_credits
	end
	
	
end
