# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :page do
  end
end

# == Schema Information
#
# Table name: pages
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text
#  active     :boolean          default(TRUE)
#  created_at :datetime
#  updated_at :datetime
#  city_id    :integer
#
# Indexes
#
#  index_pages_on_title  (title)
#
