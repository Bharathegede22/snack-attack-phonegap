class Offer < ActiveRecord::Base
	
	def self.get(code)
		offer = nil
		coupon = nil
		summary = nil
		# Promo
		offer = Offer.find_by(:promo_code =>code)
	

		# Coupon
		if offer.blank?
			coupon = CouponCode.find_by(:code =>code)
			if !coupon.blank?
			#used = coupon.used
			summary = (Offer.find_by(:id=>coupon.offer_id)).summary
			end
		else
			summary = offer.summary
		end

		return {offer: offer, coupon: coupon, summary: summary}
	end
	
	def self.active
		Rails.cache.fetch("offers") do
			Offer.find_by_sql("SELECT * FROM offers WHERE status = 1 AND visibility = 1")
		end
	end
	
end
