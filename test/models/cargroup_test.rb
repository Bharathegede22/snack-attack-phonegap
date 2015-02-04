require 'test_helper'

class CargroupTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: cargroups
#
#  id               :integer          not null, primary key
#  brand_id         :integer
#  model_id         :integer
#  name             :string(255)
#  display_name     :string(255)
#  status           :boolean          default(FALSE)
#  ended            :boolean          default(FALSE)
#  priority         :integer
#  seating          :integer
#  wait_period      :integer
#  disclaimer       :string(255)
#  description      :text
#  cartype          :integer
#  drive            :integer
#  fuel             :integer
#  manual           :boolean
#  color            :string(10)
#  power_windows    :boolean
#  aux              :boolean
#  leather_interior :boolean
#  power_seat       :boolean
#  bluetooth        :boolean
#  gps              :boolean
#  premium_sound    :boolean
#  radio            :boolean
#  sunroof          :boolean
#  power_steering   :boolean
#  dvd              :boolean
#  ac               :boolean
#  heating          :boolean
#  cd               :boolean
#  mp3              :boolean
#  alloy_wheels     :boolean
#  handsfree        :boolean
#  cruise           :boolean
#  smoking          :boolean
#  pet              :boolean
#  handicap         :boolean
#  kmpl             :float
#  seo_title        :string(255)
#  seo_description  :string(255)
#  seo_keywords     :string(255)
#  seo_h1           :string(255)
#  seo_link         :string(255)
#  kle              :boolean          default(FALSE)
#
