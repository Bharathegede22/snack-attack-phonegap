# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :picture do
  end
end

# == Schema Information
#
# Table name: pictures
#
#  id                  :integer          not null, primary key
#  pictureable_id      :integer
#  pictureable_type    :string(255)
#  avatar_file_name    :string(255)
#  avatar_content_type :string(255)
#  avatar_file_size    :integer
#  avatar_updated_at   :datetime
#
# Indexes
#
#  index_pictures_on_pictureable_type_and_pictureable_id  (pictureable_type,pictureable_id)
#
