class Sms < ActiveRecord::Base
	
	belongs_to :booking
	
	validates :api_key, :booking_id, :message, :phone, presence: true
	validates :api_key, uniqueness: true
	
end
