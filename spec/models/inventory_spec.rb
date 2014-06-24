require 'spec_helper'

describe Inventory do
	# before(:each) do
 #  		 DatabaseCleaner.clean_with :truncation
 # 	end

 	context 'association' do
 		[:city, :cargroup, :location].each do |attr|
    		it { should belong_to attr }
  		end
  	end

  	context 'validations' do
      [:cargroup_id, :city_id, :location_id, :total, :slot].each do |att|
      	it { should validate_presence_of att}
      end

      it { should validate_uniqueness_of(:cargroup_id).scoped_to([:location_id, :slot]) }
	end

  it "should decrease inventory on block_plain" do
    location = FactoryGirl.create(:location)
    cargroup = FactoryGirl.create(:cargroup)
  end
end
