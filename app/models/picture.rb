class Picture < ActiveRecord::Base

	has_attached_file :avatar, {
      :storage => :s3,
      :s3_credentials => Rails.root.join("config","s3.yml"),
      :path => ":class/:style/:hash.:extension",
      :hash_secret => YAML.load_file(Rails.root.join("config","s3.yml"))[Rails.env]["hash_secret"],
			:styles => lambda { |a|
				if a.instance.pictureable_type == 'Cargroup'
					{:thumb => "110x80>", :profile => "400x400>"}
				end
			}, 
			:convert_options => {
				:thumb => "-strip", 
				:profile => "-strip"
			}
 		}
 	
  belongs_to :pictureable, :polymorphic => true

  before_save :before_save_tasks

  private
  def before_save_tasks
    self.s3_flag = true
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
