require 'spec_helper'

describe WalletsController do
  login_user
  # NO Such Action
  # describe "GET 'topup'" do
  #   it "returns http success" do
  #     get 'topup'
  #     response.should be_success
  #   end
  # end

  describe "GET 'refund'" do
    it "returns http success" do
      get 'refund', amount: 100
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
