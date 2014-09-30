require 'test_helper'

class CarmovementTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: carmovements
#
#  id             :integer          not null, primary key
#  car_id         :integer
#  cargroup_id    :integer
#  location_id    :integer
#  starts         :datetime
#  ends           :datetime
#  active         :boolean          default(TRUE)
#  user_id        :integer
#  updated_at     :datetime
#  impact         :boolean          default(FALSE)
#  created_at     :datetime
#  reason         :integer
#  notes          :string(255)
#  starts_initial :datetime
#  ends_initial   :datetime
#  log            :text
#
# Indexes
#
#  index_carmovements_on_car_id       (car_id)
#  index_carmovements_on_cargroup_id  (cargroup_id)
#  index_carmovements_on_location_id  (location_id)
#
