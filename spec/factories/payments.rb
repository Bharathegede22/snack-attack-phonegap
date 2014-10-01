FactoryGirl.define do
  factory :payment do
  		association :booking
  		sequence(:amount) {|n| rand(1000)}
			through "PayU"
  end
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
#
# Indexes
#
#  index_payments_on_booking_id  (booking_id)
#  index_payments_on_key         (key)
#
