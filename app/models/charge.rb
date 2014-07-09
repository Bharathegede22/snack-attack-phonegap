class Charge < ActiveRecord::Base
	
	belongs_to :booking
	
	validates :booking_id, :activity, :amount, presence: true
	#validates :activity, uniqueness: {scope: :booking_id}
	validates :amount, numericality: {greater_than_or_equal_to: 0}
	
	default_scope where("(active = 1)")
	
	def activity_text
		return self.activity.split('_').map{|x| x.capitalize}.join(' ')
	end
	
end
