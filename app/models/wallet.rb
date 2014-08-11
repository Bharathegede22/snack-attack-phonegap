class Wallet < ActiveRecord::Base
	belongs_to :user
	belongs_to :charge

	validates :amount, :user_id, :charge_id, :credit,	presence: true

	scope :credits, -> {where(credit: true)}
	scope :debits, -> {where(credit: false)}
	default_scope {where('status > 1')}

	def destroy
		status = 0
		save!
	end	

end
