require 'test_helper'

class AttractionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: attractions
#
#  id              :integer          not null, primary key
#  city_id         :integer
#  name            :string(255)
#  description     :text
#  places          :text
#  best_time       :text
#  lat             :string(255)
#  lng             :string(255)
#  state           :integer
#  category        :integer
#  outstation      :boolean
#  seo_title       :string(255)
#  seo_description :string(255)
#  seo_keywords    :string(255)
#  seo_h1          :string(255)
#  seo_link        :string(255)
#
# Indexes
#
#  index_attractions_on_city_id  (city_id)
#
