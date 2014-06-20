class Offer < ActiveRecord::Base
	
	has_many :bookings
	has_many :coupon_codes
	
	def self.get(code,city)
		code = code.downcase.strip
		offer = nil
		coupon = nil
		text = ''
		
		# Promo
		offer = Offer.find_by(:promo_code => code)
		
		# Coupon
		if offer.blank?
			coupon = CouponCode.find_by(:code => code)
			offer = coupon.offer if !coupon.blank?
		end
		
		if offer
			available = CityOffer.find_by(offer_id: offer.id, city_id: city.id)
			if !available.blank?
				if offer.valid_till.blank? || offer.valid_till > Time.now
					text = "Coupon code <b>#{code.upcase}</b> has already been used." if coupon && coupon.used
				elsif !offer.valid_till.blank? && offer.valid_till < Time.now
					text = "Offer has expired."
				end
			else
				text = "Offer is not available for your city"
			end
		else
			text = "No active offer was found for <b>#{code.upcase}</b>."
		end
		return {offer: offer, coupon: coupon, error: text}
	end
	
	def self.active
		Rails.cache.fetch("offers") do
			Offer.find_by_sql("SELECT * FROM offers WHERE status = 1 AND visibility = 1")
		end
	end
	
end
