class Refund < ActiveRecord::Base
	
	belongs_to :booking
	has_one :wallet, as: :transferable
	default_scope where('(status < 5)')
	
	def through_text
		return self.through.split('_').map{|y| y.capitalize}.join(' ')
	end
	
end

# == Schema Information
#
# Table name: refunds
#
#  id         :integer          not null, primary key
#  booking_id :integer
#  status     :integer          default(0)
#  through    :string(20)
#  key        :string(255)
#  notes      :string(255)
#  amount     :decimal(8, 2)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_refunds_on_booking_id  (booking_id)
#  index_refunds_on_key         (key)
#
