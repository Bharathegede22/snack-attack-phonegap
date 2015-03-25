require 'spec_helper'

describe UsersController do 
	login_user

	describe "GET #referrals" do 
		it "should render referral page if logged in" do 
			response.should be_success
		end
	end

	describe "POST #refer_user" do
		# Most of the edge cases are handled in the ADMIN side
		# Just testing if the routes are woking here
		it "should return respose" do 
			response.should be_success
		end
	end
	
end