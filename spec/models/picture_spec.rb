require 'spec_helper'

describe Picture do
  pending "add some examples to (or delete) #{__FILE__}"
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
