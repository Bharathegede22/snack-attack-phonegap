require 'test_helper'

class InventoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: inventories
#
#  id          :integer          not null, primary key
#  cargroup_id :integer
#  location_id :integer
#  city_id     :integer
#  total       :integer          default(0)
#  slot        :datetime
#  max         :integer          default(0)
#
# Indexes
#
#  index_inventories_on_cargroup_id_and_location_id_and_slot  (cargroup_id,location_id,slot) UNIQUE
#  index_inventories_on_total                                 (total)
#
