require 'spec_helper'

describe Booking do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: bookings
#
#  id                         :integer          not null, primary key
#  car_id                     :integer
#  location_id                :integer
#  user_id                    :integer
#  booked_by                  :integer
#  cancelled_by               :integer
#  comment                    :string(255)
#  days                       :integer
#  hours                      :integer
#  estimate                   :decimal(8, 2)
#  discount                   :decimal(8, 2)
#  total                      :decimal(8, 2)
#  starts                     :datetime
#  ends                       :datetime
#  cancelled_at               :datetime
#  returned_at                :datetime
#  ip                         :string(255)
#  status                     :integer          default(0)
#  jsi                        :string(10)
#  user_name                  :string(255)
#  user_email                 :string(255)
#  user_mobile                :string(255)
#  created_at                 :datetime
#  updated_at                 :datetime
#  start_km                   :string(10)
#  end_km                     :string(10)
#  normal_days                :integer          default(0)
#  normal_hours               :integer          default(0)
#  discounted_days            :integer          default(0)
#  discounted_hours           :integer          default(0)
#  actual_starts              :datetime
#  actual_ends                :datetime
#  last_starts                :datetime
#  last_ends                  :datetime
#  early                      :boolean          default(FALSE)
#  late                       :boolean          default(FALSE)
#  extended                   :boolean          default(FALSE)
#  rescheduled                :boolean          default(FALSE)
#  fuel_starts                :integer
#  fuel_ends                  :integer
#  daily_fare                 :integer
#  hourly_fare                :integer
#  hourly_km_limit            :integer
#  daily_km_limit             :integer
#  excess_kms                 :integer          default(0)
#  notes                      :text
#  cargroup_id                :integer
#  fleet_id_start             :integer
#  fleet_id_end               :integer
#  individual_start           :integer
#  individual_end             :integer
#  transport                  :integer
#  unblocks                   :datetime
#  outstation                 :boolean          default(FALSE)
#  checkout                   :datetime
#  confirmation_key           :string(20)
#  balance                    :integer
#  ref_initial                :string(255)
#  ref_immediate              :string(255)
#  promo                      :string(255)
#  credit_status              :integer          default(0)
#  offer_id                   :integer
#  pricing_id                 :integer
#  corporate_id               :integer
#  city_id                    :integer
#  pricing_mode               :string(2)
#  medium                     :string(20)
#  shortened                  :boolean          default(FALSE)
#  total_fare                 :integer
#  deposit_status             :integer          default(0)
#  carry                      :boolean          default(FALSE)
#  hold                       :boolean          default(FALSE)
#  release_payment            :boolean          default(FALSE)
#  settled                    :boolean          default(FALSE)
#  actual_cargroup_id         :integer
#  actual_cargroup_id_count   :integer          default(0)
#  car_id_count               :integer          default(0)
#  cargroup_id_count          :integer          default(0)
#  ends_count                 :integer          default(0)
#  end_km_count               :integer          default(0)
#  location_id_count          :integer          default(0)
#  returned_at_count          :integer          default(0)
#  starts_count               :integer          default(0)
#  start_km_count             :integer          default(0)
#  defer_deposit              :boolean
#  insufficient_deposit       :boolean          default(FALSE)
#  fleet_checklist_by         :integer
#  start_checklist_by         :integer
#  end_checklist_by           :integer
#  release_payment_updated_at :datetime
#  recorded_distance          :decimal(10, 2)
#
# Indexes
#
#  index_bookings_on_car_id            (car_id)
#  index_bookings_on_cargroup_id       (cargroup_id)
#  index_bookings_on_confirmation_key  (confirmation_key)
#  index_bookings_on_ends              (ends)
#  index_bookings_on_jsi               (jsi)
#  index_bookings_on_location_id       (location_id)
#  index_bookings_on_ref_immediate     (ref_immediate)
#  index_bookings_on_ref_initial       (ref_initial)
#  index_bookings_on_starts            (starts)
#  index_bookings_on_unblocks          (unblocks)
#  index_bookings_on_user_email        (user_email)
#  index_bookings_on_user_id           (user_id)
#  index_bookings_on_user_mobile       (user_mobile)
#
