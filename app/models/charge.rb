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

	def security?
		activity == 'security_deposit' && !refund?
	end

	def security_refund?
		activity == 'security_deposit_refund' && refund?
	end

	def refund?
		refund == 1
	end

	def early_return?
		['early_return_charge','early_return_refund'].include? activity
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

# == Schema Information
#
# Table name: charges
#
#  id                      :integer          not null, primary key
#  booking_id              :integer
#  refund                  :integer          default(0)
#  activity                :string(40)
#  hours                   :integer          default(0)
#  billed_total_hours      :integer          default(0)
#  billed_standard_hours   :integer          default(0)
#  billed_discounted_hours :integer          default(0)
#  estimate                :decimal(8, 2)    default(0.0)
#  discount                :decimal(8, 2)    default(0.0)
#  amount                  :decimal(8, 2)    default(0.0)
#  notes                   :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#  active                  :boolean          default(TRUE)
#
# Indexes
#
#  index_charges_on_booking_id  (booking_id)
#
