require 'spec_helper'

describe WalletsController do

  describe "GET 'topup'" do
    it "returns http success" do
      get 'topup'
      response.should be_success
    end
  end

  describe "GET 'refund'" do
    it "returns http success" do
      get 'refund'
      response.should be_success
    end
  end

  describe "GET 'show'" do
    it "returns http success" do
      get 'show'
      response.should be_success
    end
  end

end
