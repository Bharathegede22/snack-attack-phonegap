class Credit < ActiveRecord::Base
	
	belongs_to :creditable, :polymorphic => true
	after_create :after_create_tasks
	belongs_to :user
	
	default_scope where("(status = 1)")

	def after_create_tasks
		user.update_credits
	end
	
	
end
