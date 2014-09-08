class Carmovement < ActiveRecord::Base
	
	belongs_to :car
	belongs_to :cargroup
	belongs_to :location
	has_one :debug, :as => :debugable, dependent: :destroy
	
	default_scope { where("(active = 1)") }
	
end
