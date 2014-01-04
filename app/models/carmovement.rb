class Carmovement < ActiveRecord::Base
	
	belongs_to :car
	belongs_to :cargroup
	belongs_to :location
	
end
