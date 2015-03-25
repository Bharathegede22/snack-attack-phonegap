class Wallet < ActiveRecord::Base
	belongs_to :user
	belongs_to :transferable, polymorphic: true

	validates :amount, :user_id,	presence: true
	after_save :update_user_total
	before_create :update_booking
	
	scope :credits, -> {where(credit: true)}
	scope :debits, -> {where(credit: false)}
	default_scope {where('status > 0')}

	def destroy
		status = 0
		save!
	end	

	def update_user_total
		user.calculate_wallet_total_amount
	end

	def update_booking
		self.booking_id = transferable.booking_id unless transferable.nil?
	end
end

# == Schema Information
#
# Table name: wallets
#
#  id                :integer          not null, primary key
#  transferable_id   :integer
#  transferable_type :string(255)
#  user_id           :integer
#  amount            :decimal(8, 2)    default(0.0)
#  credit            :boolean
#  status            :integer          default(0)
#  created_at        :datetime
#  updated_at        :datetime
#  booking_id        :integer
#
