require 'test_helper'

class PaymentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: payments
#
#  id                           :integer          not null, primary key
#  booking_id                   :integer
#  status                       :integer          default(0)
#  through                      :string(20)
#  key                          :string(255)
#  notes                        :text
#  amount                       :decimal(8, 2)
#  created_at                   :datetime
#  updated_at                   :datetime
#  mode                         :integer
#  qb_id                        :integer
#  refunded_amount              :integer          default(0)
#  deposit_available_for_refund :integer          default(0)
#  deposit_paid                 :integer          default(0)
#  rrn                          :string(255)
#  auth_id                      :string(255)
#
# Indexes
#
#  index_payments_on_booking_id  (booking_id)
#  index_payments_on_key         (key)
#
