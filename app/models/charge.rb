class Charge < ActiveRecord::Base
	
	belongs_to :booking
	
	validates :booking_id, :activity, :amount, presence: true
	#validates :activity, uniqueness: {scope: :booking_id}
	validates :amount, numericality: {greater_than_or_equal_to: 0}
	
	after_create :after_create_tasks
	after_save :after_save_tasks
	
	default_scope where("(active = 1)")
	
	def activity_text
		return self.activity.split('_').map{|x| x.capitalize}.join(' ')
	end
	
	def destroy
		active=false
		save!
	end

	protected
	
	def after_create_tasks
		self.booking.update_column(:deposit_status, 1) if self.activity == 'security_deposit'
		self.booking.update_column(:deposit_status, 3) if self.activity == 'security_deposit_refund'
		true
	end

	def after_save_tasks
		Booking.recalculate(self.booking_id)
	end
	
end
