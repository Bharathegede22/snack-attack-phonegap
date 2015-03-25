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

# == Schema Information
#
# Table name: inventories
#
#  id          :integer          not null, primary key
#  cargroup_id :integer
#  location_id :integer
#  city_id     :integer
#  total       :integer          default(0)
#  slot        :datetime
#  max         :integer          default(0)
#
# Indexes
#
#  index_inventories_on_cargroup_id_and_location_id_and_slot  (cargroup_id,location_id,slot) UNIQUE
#  index_inventories_on_total                                 (total)
#
