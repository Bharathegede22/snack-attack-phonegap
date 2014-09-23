class Email < ActiveRecord::Base
	
	belongs_to :user
	validates :user_id, :activity, presence: true
	
end
