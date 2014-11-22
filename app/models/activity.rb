class Activity < ActiveRecord::Base
  belongs_to :booking
  belongs_to :transferred_via, polymorphic: true


  ACTIVITIES = {refund_requested: "refund_requested", defer_deposit: "defer_deposit", security_deposit_paid: "security_deposit_paid", on_hold: "on_hold"}

  def self.create_activity(params)
    create!(user_id: params[:user_id], booking_id: params[:booking_id] , activity: params[:activity], amount: params[:amount], transferred_via: params[:transferred_via], medium: "Web")
  end
end
