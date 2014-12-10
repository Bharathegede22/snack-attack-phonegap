FactoryGirl.define do 
  factory :credit do
    source_name Credit::SOURCE_NAME_INVERT["Booking"]
    action 1
    status 1
    amount 100
    user
    #creditable {FactoryGirl.create :booking}
  end 
end