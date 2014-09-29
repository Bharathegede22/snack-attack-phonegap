class Offer < ActiveRecord::Base
	
	has_many :bookings
	has_many :coupon_codes
	has_many :city_offers
	has_many :cities, through: :city_offers
	def check_output_condition
		return true if self.output_condition.nil?
		output_condition = self.output_condition.gsub(/\w+/){|word| @replace.fetch(word,word)}
		Charge.find_by_sql(output_condition).blank? ? (return false) : (return true)
	end

	def check_booking_condition
		return true if self.booking_condition.nil?
		booking_condition = self.booking_condition.gsub(/\w+/) {|word| @replace.fetch(word,word)}
		Booking.find_by_sql(booking_condition).blank? ? (return false) : (return true)
	end

	def check_user_condition
		return true if self.user_condition.nil?
		user_condition = self.user_condition.gsub(/\w+/){|word| @replace.fetch(word,word)}
		User.find_by_sql(user_condition).blank? ? (return false) : (return true)
	end

	def self.get(code,city)
		code = code.downcase.strip
		offer = nil
		coupon = nil
		text = ''
		# Promo
		offer = Offer.where("promo_code = '#{code}' OR promo_code LIKE '%#{code},%' OR promo_code LIKE '%#{code}'").first
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
	
	def validate_offer(user_id,booking_id)
		none = ''
		text = "Coupon code <b>#{self.promo_code.upcase}</b> cannot be applied to the current booking"
		@replace = {"USER_ID" => user_id, "TIME_NOW" => Time.now.to_s(:db), "BOOKING_ID" => booking_id}
		return text  unless self.check_user_condition
		return text  unless self.check_booking_condition
		return text  unless self.check_output_condition
		return none
	end
	
end

# == Schema Information
#
# Table name: offers
#
#  id                :integer          not null, primary key
#  heading           :string(255)
#  description       :text
#  promo_code        :string(255)
#  status            :boolean          default(TRUE)
#  disclaimer        :text
#  visibility        :integer          default(0)
#  user_condition    :text
#  booking_condition :text
#  output_condition  :text
#  created_at        :datetime
#  updated_at        :datetime
#  summary           :string(255)
#  instructions      :text
#  valid_till        :datetime
#
