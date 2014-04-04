class Review < ActiveRecord::Base
	
	validates :rating_tech, length: { in: 1..5 }, numericality: { only_integer: true }
	validates :rating_friendly, length: { in: 1..5 }, numericality: { only_integer: true }
	validates :rating_condition, length: { in: 1..5 }, numericality: { only_integer: true }
	validates :rating_location, length: { in: 1..5 }, numericality: { only_integer: true }
	validates :comment, length: {in: 0..1000}
	validates :booking_id, uniqueness: true	
end
