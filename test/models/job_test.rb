require 'test_helper'

class JobTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: jobs
#
#  id              :integer          not null, primary key
#  title           :string(255)
#  description     :text
#  hire_type       :integer
#  min_workex      :integer
#  relevant_workex :integer
#  department      :integer
#  status          :boolean
#  created_at      :datetime
#  updated_at      :datetime
#
