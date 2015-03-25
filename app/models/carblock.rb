class Carblock < ActiveRecord::Base
	
	belongs_to :car
	has_one :debug, :as => :debugable, dependent: :destroy
	
	default_scope { where("(active = 1)") }
	
end

# == Schema Information
#
# Table name: carblocks
#
#  id             :integer          not null, primary key
#  car_id         :integer
#  activity       :integer
#  notes          :string(255)
#  starts         :datetime
#  ends           :datetime
#  created_at     :datetime
#  cargroup_id    :integer
#  active         :boolean          default(TRUE)
#  user_id        :integer
#  updated_at     :datetime
#  impact         :boolean          default(FALSE)
#  starts_initial :datetime
#  ends_initial   :datetime
#  source         :boolean
#  log            :text
#  checklist_by   :integer
#  medium         :string(20)
#
# Indexes
#
#  index_carblocks_on_car_id  (car_id)
#
