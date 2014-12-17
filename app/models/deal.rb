class Deal < ActiveRecord::Base

	def self.createDeal(offer_date, starts, ends, car, loc, disc)
		d = self.new
		d.offer_date = offer_date.beginning_of_day
		d.starts = starts
		d.ends = ends
		d.car_id = car
		d.location_id = loc
		d.discount = disc
		d.save!
	end

end

# == Schema Information
#
# Table name: deals
#
#  id          :integer          not null, primary key
#  starts      :datetime         not null
#  ends        :datetime         not null
#  offer_start :datetime         not null
#  offer_end   :datetime         not null
#  cargroup_id :integer          not null
#  car_id      :integer          not null
#  location_id :integer          not null
#  booking_id  :integer
#  discount    :integer          not null
#  sold_out    :boolean          default(FALSE)
#  created_at  :datetime
#  updated_at  :datetime
#  logged_at   :datetime
#
# Indexes
#
#  index_deals_on_booking_id   (booking_id)
#  index_deals_on_car_id       (car_id)
#  index_deals_on_cargroup_id  (cargroup_id)
#  index_deals_on_ends         (ends)
#  index_deals_on_location_id  (location_id)
#  index_deals_on_offer_end    (offer_end)
#  index_deals_on_offer_start  (offer_start)
#  index_deals_on_starts       (starts)
#
