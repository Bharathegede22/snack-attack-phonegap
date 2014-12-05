class Sms < ActiveRecord::Base
	
	belongs_to :booking
	
	validates :api_key, :booking_id, :message, :phone, presence: true
	validates :api_key, uniqueness: true
	
end

# == Schema Information
#
# Table name: sms
#
#  id            :integer          not null, primary key
#  booking_id    :integer
#  phone         :string(10)
#  message       :text
#  status        :integer          default(0)
#  error_message :string(255)
#  api_key       :string(255)
#  delivered_on  :datetime
#  created_at    :datetime
#  updated_at    :datetime
#  activity      :string(255)
#
# Indexes
#
#  index_sms_on_api_key     (api_key)
#  index_sms_on_booking_id  (booking_id)
#  index_sms_on_created_at  (created_at)
#
