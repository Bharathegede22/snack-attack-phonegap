class Carblock < ActiveRecord::Base
	
	belongs_to :car
	has_one :debug, :as => :debugable, dependent: :destroy
end
