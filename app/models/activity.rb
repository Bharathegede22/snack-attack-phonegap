class Activity < ActiveRecord::Base
  belongs_to :booking
  belongs_to :transferred_via, polymorphic: true


  ACTIVITIES = {refund_requested: "refund_requested", defer_deposit: "defer_deposit", security_deposit_paid: "security_deposit_paid", on_hold: "on_hold"}

  def self.create_activity(params)
    create!(user_id: params[:user_id], booking_id: params[:booking_id] , activity: params[:activity], amount: params[:amount], transferred_via: params[:transferred_via], medium: "Web")
  end
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
