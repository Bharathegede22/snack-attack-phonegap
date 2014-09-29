# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :debug do
    debugable_id 1
    debugable_type "MyString"
    description "MyText"
  end
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
