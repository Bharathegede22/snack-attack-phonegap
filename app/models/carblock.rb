class Carblock < ActiveRecord::Base
	
	belongs_to :car
	has_one :debug, :as => :debugable, dependent: :destroy
	
	default_scope { where("(active = 1)") }
	
end
