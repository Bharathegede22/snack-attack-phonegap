require 'spec_helper'

describe Location do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: locations
#
#  id              :integer          not null, primary key
#  city_id         :integer
#  name            :string(255)
#  address         :string(255)
#  lat             :string(255)
#  lng             :string(255)
#  map_link        :string(255)
#  description     :text
#  mobile          :string(15)
#  email           :string(100)
#  status          :integer          default(1)
#  inventory_done  :boolean          default(FALSE)
#  ended           :boolean          default(FALSE)
#  disclaimer      :string(255)
#  block_time      :integer
#  zone_id         :integer
#  hub_id          :integer
#  user_id         :integer
#  cash            :decimal(7, 2)    default(0.0)
#  seo_title       :string(255)
#  seo_description :string(255)
#  seo_keywords    :string(255)
#  seo_h1          :string(255)
#  seo_link        :string(255)
#  kle_enabled     :datetime
#
