require 'spec_helper'

describe Activity do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: activities
#
#  id                   :integer          not null, primary key
#  user_id              :integer
#  booking_id           :integer
#  amount               :decimal(8, 2)    default(0.0)
#  transferred_via_id   :integer
#  transferred_via_type :string(255)
#  activity             :string(255)
#  notes                :string(255)
#  medium               :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  index_activities_on_booking_id  (booking_id)
#  index_activities_on_user_id     (user_id)
#
