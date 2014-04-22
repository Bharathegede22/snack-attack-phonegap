class Offer < ActiveRecord::Base
	# t.string :heading
	# t.text :description
	# t.string :promo_code
	# t.string :status
	# t.text :disclaimer
	# t.string :visibility
	# t.text :user_condition
	# t.text :booking_condition
	# t.text :output_condition
	
	STATUSES = [ACTIVE = 'Active', INACTIVE ='Inactive']
	VISIBILITIES = [VISIBLE_ALL = 'All', VISIBLE_NONE ='None']

	def status_enum
   		[[ACTIVE],[INACTIVE]]
	end
	
	def visibility_enum
   		[[VISIBLE_ALL], [VISIBLE_NONE]]
	end
end
