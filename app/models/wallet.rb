class Wallet < ActiveRecord::Base
	belongs_to :user
	belongs_to :transferable, polymorphic: true

	validates :amount, :user_id,	presence: true
	after_save :update_user_total

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
end
