FactoryGirl.define do 
  factory :credit do
    source_name "booking"
    action 1
    status 1
    amount 100
    user
    #creditable {FactoryGirl.create :booking}
  end 
end