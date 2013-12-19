class Payment < ActiveRecord::Base
	
	belongs_to :booking
	
	validates :booking_id, :through, :amount, presence: true
	#validates :through, uniqueness: {scope: [:booking_id, :key]}
	
	after_save :after_save_tasks
	
	def encoded_id
		CommonHelper.encode('payment', self.id)
	end
	
	def mode_text
		case self.mode
		when 0 then 'Credit Card'
		when 1 then 'Debit Card'
		end
	end
	
	def status_text
		case self.status
		when 0 then 'Initiated'
		when 1 then 'Success'
		when 2 then 'Failed'
		when 3 then 'Pending'
		end
	end
	
	def through_text
		return self.through.capitalize
	end
	
	protected
	
	def after_save_tasks
		if self.status == 1
			b = self.booking
			if b
				b.status = 1 if b.status == 0
				b.notes += "<b>" + Time.now.strftime("%d/%m/%y %I:%M %p") + " : </b> Rs." + self.amount.to_s + " - Payment Received through <u>" + self.through_text + "</u>.<br/>"
				b.save(:validate => false)
			end
		end
	end
	
end
