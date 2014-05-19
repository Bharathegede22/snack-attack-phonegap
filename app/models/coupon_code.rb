class CouponCode < ActiveRecord::Base
	
	belongs_to :booking
	belongs_to :offer
	 
end
