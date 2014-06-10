FactoryGirl.define do
  factory :payment do
  		association :booking
  		sequence(:amount) {|n| rand(1000)}
			through "PayU"
  end
end
