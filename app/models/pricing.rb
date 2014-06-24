class Pricing < ActiveRecord::Base
	DEFAULT_VERSION = "v1"
	belongs_to :cargroup
	belongs_to :city
	validates :monthly_fare, :weekly_fare, :hourly_fare,:monthly_kms, :weekly_kms, :hourly_kms, presence: true

	
	def self.update(city_id,cargroup_id, hourly_fare, monthly_fare, weekly_fare, hourly_kms, monthly_kms, weekly_kms, effective_from = Time.now)
		Pricing.create(city_id: city_id, cargroup_id: cargroup_id, monthly_fare: monthly_fare, weekly_fare: weekly_fare, hourly_fare: hourly_fare, monthly_kms: monthly_kms, weekly_kms: weekly_kms, hourly_kms: hourly_kms, starts: starts, status: true)
	end

	# def self.for_type(cargroup_id, city_id, given_time = Time.now)
	# 	Pricing.where("cargroup_id = ? AND city_id = ? AND effective_from < ?", cargroup_id, city_id, given_time).sort_by(&:effective_from).last rescue nil
	# end

	# def self.present(cargroup_id,city_id,starts)
	# 	Pricing.where("cargroup_id =? AND city_id =? AND ")
	# end

	# def self.applicable_version(cargroup_id,city_id,given_time = Time.now)
	# 	Pricing.where("cargroup_id = ? AND city_id = ? AND starts < ?", cargroup_id, city_id, given_time).sort_by(&:starts).last rescue nil
	# end

	def self.latest_pricing(booking)
		cargroup_id = booking.cargroup_id
		city_id = Location.find_by_id(booking.location_id).city_id
		return Pricing.where("cargroup_id = ? AND city_id = ?", cargroup_id, city_id).sort_by(&:starts).last.id rescue nil
	end

	def self.pricing_verison(pricing_id)
		#return Pricing.find_by_id(pricing_id).version
		Rails.cache.fetch("pricing-city-#{pricing_id}") do
		 	return Pricing.find_by_id(pricing_id).version
		end
	end

	def self.get_pricing(cargroup_id,city_id)
		return Pricing.where("cargroup_id = ? AND city_id = ? AND version = ?" , cargroup_id, city_id, DEFAULT_VERSION).sort_by(&:starts).last rescue nil
	end
end
