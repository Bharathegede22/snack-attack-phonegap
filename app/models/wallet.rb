class Wallet < ActiveRecord::Base
	belongs_to :user
	belongs_to :transferable, polymorphic: true

	validates :amount, :user_id, :transferable_id, :transferable_type,	presence: true

	scope :credits, -> {where(credit: true)}
	scope :debits, -> {where(credit: false)}
	default_scope {where('status > 0')}

	def destroy
		status = 0
		save!
	end	

end
