require 'test_helper'

class ReviewTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: reviews
#
#  id               :integer          not null, primary key
#  booking_id       :integer
#  user_id          :integer
#  car_id           :integer
#  location_id      :integer
#  title            :string(255)
#  comment          :text
#  ip               :string(255)
#  active           :boolean          default(FALSE)
#  created_at       :datetime
#  updated_at       :datetime
#  cargroup_id      :integer
#  jsi              :string(10)
#  rating_friendly  :decimal(2, 1)
#  rating_tech      :decimal(2, 1)
#  rating_condition :decimal(2, 1)
#  rating_location  :decimal(2, 1)
#
# Indexes
#
#  index_reviews_on_booking_id   (booking_id)
#  index_reviews_on_car_id       (car_id)
#  index_reviews_on_cargroup_id  (cargroup_id)
#  index_reviews_on_jsi          (jsi)
#  index_reviews_on_location_id  (location_id)
#  index_reviews_on_user_id      (user_id)
#
