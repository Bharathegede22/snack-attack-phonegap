module WalletsHelper
	def create_refund(amount)
		amount = amount.to_i.tap{|a| return false if a <= 0}
		return false if current_user.wallet_total_amount < amount 
		Wallet.new(user_id: current_user.id, amount: amount, status: true).save
	end

end
