class Image < ActiveRecord::Base
	
	has_attached_file :avatar, {
			#:url => "/system/:hash.:extension",
			#:hash_secret => "sjdsjuuwwndsajdsuwdnwqsshwssqsqgaodkfedwdnmqsuiqwgqqq",
			:styles => lambda { |a|
				if a.instance.imageable_type == 'Booking'
					{:thumb => "200x200>", :profile => "1000x1000>"}
				elsif a.instance.imageable_type == 'Cartype'
					{:thumb => "100x100>", :profile => "500x360>"}
				elsif a.instance.imageable_type == 'License'
					{:thumb => "200x200>", :profile => "1000x1000>"}
				elsif a.instance.imageable_type == 'User'
					{:thumb => "100x100>", :profile => "300x300>"}
				end
			}, 
			:convert_options => {
				:thumb => "-strip", 
				:profile => "-strip"
			}
 		} 
  
  belongs_to :imageable, :polymorphic => true
  
  validates_attachment_presence :avatar
  validates :imageable_id, uniqueness: {scope: :imageable_type}
  
end
