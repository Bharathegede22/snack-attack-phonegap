FactoryGirl.define do 
  factory :brand do
    sequence (:name) {|n| "brand#{rand(100000)}"}
  end 
end