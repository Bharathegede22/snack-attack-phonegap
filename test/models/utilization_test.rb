require 'test_helper'

class UtilizationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: utilizations
#
#  id                  :integer          not null, primary key
#  booking_id          :integer
#  car_id              :integer
#  cargroup_id         :integer
#  location_id         :integer
#  minutes             :integer          default(0)
#  billed_minutes      :integer          default(0)
#  billed_minutes_last :integer          default(0)
#  wday                :integer
#  revenue             :decimal(7, 2)    default(0.0)
#  revenue_last        :decimal(7, 2)    default(0.0)
#  day                 :date
#  fuel_margin         :float
#
# Indexes
#
#  index_utilizations_on_booking_id            (booking_id)
#  index_utilizations_on_car_id_and_wday       (car_id,wday)
#  index_utilizations_on_cargroup_id_and_wday  (cargroup_id,wday)
#  index_utilizations_on_location_id_and_wday  (location_id,wday)
#
