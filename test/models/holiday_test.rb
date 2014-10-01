require 'test_helper'

class HolidayTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: holidays
#
#  id       :integer          not null, primary key
#  name     :string(255)
#  day      :date
#  internal :boolean          default(FALSE)
#  repeat   :boolean          default(FALSE)
#
# Indexes
#
#  index_holidays_on_repeat  (repeat)
#
