require 'test_helper'

class CarTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: cars
#
#  id                 :integer          not null, primary key
#  cargroup_id        :integer
#  location_id        :integer
#  name               :string(255)
#  status             :integer          default(0)
#  mileage            :integer          default(0)
#  vin                :string(255)
#  license            :string(255)
#  insurer            :string(255)
#  policy             :string(255)
#  wait_period        :integer
#  allindia           :boolean
#  color              :string(10)
#  leather_interior   :boolean
#  mp3                :boolean
#  gps                :boolean
#  bluetooth          :boolean
#  radio              :boolean
#  dvd                :boolean
#  aux                :boolean
#  roofrack           :boolean
#  alloy_wheels       :boolean
#  handsfree          :boolean
#  child_seat         :boolean
#  smoking            :boolean
#  pet                :boolean
#  handicap           :boolean
#  jsi                :string(255)
#  jsi_old            :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  starts             :date
#  ends               :date
#  kle_installed      :boolean          default(FALSE)
#  immobilizer        :boolean          default(FALSE)
#  tguid              :string(255)
#  km_reading         :string(11)
#  fuel_reading       :integer          default(0)
#  emi_start_date     :date
#  financier_name     :string(255)
#  loan_account_num   :string(255)
#  city_of_purchase   :string(255)
#  rate_of_interest   :decimal(6, 4)
#  loan_amount        :decimal(10, 2)
#  loan_tenure_months :integer
#  car_regn_date      :date
#  city_id            :integer
#
# Indexes
#
#  index_cars_on_cargroup_id  (cargroup_id)
#  index_cars_on_ends         (ends)
#  index_cars_on_location_id  (location_id)
#  index_cars_on_starts       (starts)
#
