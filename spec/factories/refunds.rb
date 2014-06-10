FactoryGirl.define do
  factory :refund do
		
		through "PAYU"
		
		booking {(FactoryGirl.create :booking)}
		amount 0
  end
end