class Pricing < ActiveRecord::Base
	
	belongs_to :cargroup
	belongs_to :city
	
	has_many :bookings
	
	def hourly_discounted
		if self.hourly_discounted_fare.blank?
			return (self.hourly_fare*(100 - self.mode::WEEKDAY_DISCOUNT)/100.0).to_i
		else
			return self.hourly_discounted_fare
		end
	end
	
	def daily_discounted
		if self.daily_discounted_fare.blank?
			return (self.daily_fare*(100 - self.mode::WEEKDAY_DISCOUNT)/100.0).to_i
		else
			return self.daily_discounted_fare
		end
	end
	
	def mode
		return "Pricing#{self.version}".constantize
	end
	
end

# == Schema Information
#
# Table name: pricings
#
#  id                         :integer          not null, primary key
#  cargroup_id                :integer
#  city_id                    :integer
#  hourly_fare                :integer
#  daily_fare                 :integer
#  weekly_fare                :integer
#  monthly_fare               :integer
#  hourly_kms                 :integer
#  daily_kms                  :integer
#  weekly_kms                 :integer
#  monthly_kms                :integer
#  starts                     :date
#  version                    :string(6)
#  status                     :boolean          default(FALSE)
#  excess_kms                 :decimal(5, 2)
#  hourly_discounted_fare     :integer
#  daily_discounted_fare      :integer
#  hourly_bod_fare            :integer
#  daily_bod_fare             :integer
#  weekly_percentage_discount :integer          default(0)
#
# Indexes
#
#  index_pricings_on_city_id_and_cargroup_id  (city_id,cargroup_id)
#
