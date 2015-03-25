
FactoryGirl.define do 
  factory :image do
        avatar_file_name "test"
        avatar_content_type "License"
        imageable_type "License"
  end 
end

# == Schema Information
#
# Table name: images
#
#  id                  :integer          not null, primary key
#  imageable_id        :integer
#  imageable_type      :string(255)
#  avatar_file_name    :string(255)
#  avatar_content_type :string(255)
#  avatar_file_size    :integer
#  avatar_updated_at   :datetime
#
# Indexes
#
#  index_images_on_imageable_type_and_imageable_id  (imageable_type,imageable_id)
#
