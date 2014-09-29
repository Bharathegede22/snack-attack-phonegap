# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :charge do
    association :booking
  end
end

# == Schema Information
#
# Table name: charges
#
#  id                      :integer          not null, primary key
#  booking_id              :integer
#  refund                  :integer          default(0)
#  activity                :string(40)
#  hours                   :integer          default(0)
#  billed_total_hours      :integer          default(0)
#  billed_standard_hours   :integer          default(0)
#  billed_discounted_hours :integer          default(0)
#  estimate                :decimal(8, 2)    default(0.0)
#  discount                :decimal(8, 2)    default(0.0)
#  amount                  :decimal(8, 2)    default(0.0)
#  notes                   :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#  active                  :boolean          default(TRUE)
#
# Indexes
#
#  index_charges_on_booking_id  (booking_id)
#
