class Picture < ActiveRecord::Base

	has_attached_file :avatar, {
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
  
end