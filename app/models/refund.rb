class Refund < ActiveRecord::Base
	
	belongs_to :booking
	has_one :wallet, as: :transferable
	default_scope where('(status < 5)')
	
	def through_text
		return self.through.split('_').map{|y| y.capitalize}.join(' ')
	end
	
end
