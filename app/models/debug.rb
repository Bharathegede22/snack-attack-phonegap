class Debug < ActiveRecord::Base
	belongs_to :debugable, :polymorphic => true
	validates :debugable_id, :debugable_type, presence: true
  	validates :debugable_id, uniqueness: {scope: :debugable_type}
end
