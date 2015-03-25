# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :zone do
    name "MyString"
    city_id 1
  end
end

# == Schema Information
#
# Table name: zones
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  city_id         :integer
#  created_at      :datetime
#  updated_at      :datetime
#  seo_title       :string(255)
#  seo_description :string(255)
#  seo_keywords    :string(255)
#  seo_h1          :string(255)
#  seo_link        :string(255)
#
