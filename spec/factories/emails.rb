# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :email do
  	user {(FactoryGirl.create(:user))}
  	activity "Activity"
  end
end

# == Schema Information
#
# Table name: emails
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  activity   :string(30)
#  created_at :date
#  booking_id :integer
#
# Indexes
#
#  index_emails_on_booking_id  (booking_id)
#  index_emails_on_created_at  (created_at)
#  index_emails_on_user_id     (user_id)
#
