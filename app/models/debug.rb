class Debug < ActiveRecord::Base
	
	belongs_to :debugable, :polymorphic => true
	validates :debugable_id, :debugable_type, presence: true
	validates :debugable_id, uniqueness: {scope: :debugable_type}
	
end

# == Schema Information
#
# Table name: debugs
#
#  id             :integer          not null, primary key
#  debugable_id   :integer
#  debugable_type :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  sourcable_id   :integer
#  sourcable_type :string(255)
#  through        :string(255)
#  action         :string(255)
#  status         :string(255)
#  medium         :string(255)
#  message        :string(255)
#
