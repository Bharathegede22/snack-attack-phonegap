require 'spec_helper'

describe User do
  pending "add some examples to (or delete) #{__FILE__}"


	describe "#send_otp_verification_sms", focus: true do

    it "should send OTP to unverified_phone if unverified_phone is present" do
      @user = FactoryGirl.create(:user, unverified_phone: '9930000000')
      @user.send_otp_verification_sms
      expect(@user.otp).not_to be nil # otp generated?
      expect(@user.otp_valid_till).to be < 1.hour.from_now # check validity
      expect(@user.unverified_phone).not_to be nil
    end

    it "should not send more than 3 sms within hour" do
      @user = FactoryGirl.create(:user, unverified_phone: '9930000000')
      4.times { @user.send_otp_verification_sms }
      expect(@user.otp_attempts).not_to be > 3 #Sms.where(:phone => '', :activity => 'otp_phone_verification').length.should_not be > 3
    end

    it "should send OTP to primary phone if unverified_phone if it is nil" do
      @user = FactoryGirl.create(:user, phone: '9930000000')
      expect(@user.unverified_phone).to be nil
      @user.send_otp_verification_sms
      expect(@user.otp).not_to be nil # otp generated?
      expect(@user.otp_valid_till).to be < 1.hour.from_now # check validity
    end
  end

  describe "#verify_otp", focus: true do
    # Creates user and send OTP sms
    def create_user_and_send_otp_sms(args={})
      @user = FactoryGirl.create(:user, args)
      @user.send_otp_verification_sms
      @user
    end

    it "should verify otp for unverified_phone" do
      @user = create_user_and_send_otp_sms(unverified_phone: '9930000000')
      expect(@user.phone_verified).to be false
      expect(@user.unverified_phone).not_to be nil
      @user.verify_otp(@user.otp)
      expect(@user.phone_verified).to be true
      expect(@user.unverified_phone).to be nil
    end

    it "should verify otp for primary phone" do
      @user = create_user_and_send_otp_sms(phone: '9930000000')
      expect(@user.phone_verified).to be false
      expect(@user.unverified_phone).to be nil
      expect(@user.phone).not_to be nil
      @user.verify_otp(@user.otp)
      expect(@user.phone_verified).to be true
    end

    it "should return err if otp mismatch" do
      @user = create_user_and_send_otp_sms(phone: '9930000000')
       #setting any number
      expect(@user.verify_otp('234234')[:err]).to eq('otp code mismatch')
    end

    it "should give credits to the referred user" do
      referrer_user = FactoryGirl.create(:user)
      @user = create_user_and_send_otp_sms(phone: '9930000000')
      referral = Referral.create(referral_user_id: referrer_user.id, referral_email: @user.email, signup_flag: 1)
      @user.verify_otp(@user.otp)
      expect(@user.sign_up_credits_earned?).to be true
      # It should not give duplicate sign up credits
      Referral.validate_reference @user
      signup_credits = @user.credits.where(:source_name => Credit::SOURCE_NAME_INVERT["Sign up"]).collect(&:amount).sum.to_i
      expect(signup_credits).to eq(Credit::REFERRAL_CREDIT)
    end

  end

end

# == Schema Information
#
# Table name: users
#
#  id                              :integer          not null, primary key
#  name                            :string(255)
#  dob                             :date
#  phone                           :string(15)
#  license                         :string(255)
#  status                          :integer          default(0)
#  pincode                         :string(8)
#  role                            :integer          default(0)
#  mobile                          :boolean          default(FALSE)
#  email                           :string(255)      not null
#  ref_code                        :string(255)
#  encrypted_password              :string(255)      default(""), not null
#  reset_password_token            :string(255)
#  reset_password_sent_at          :datetime
#  remember_created_at             :datetime
#  sign_in_count                   :integer          default(0)
#  current_sign_in_at              :datetime
#  last_sign_in_at                 :datetime
#  current_sign_in_ip              :string(255)
#  last_sign_in_ip                 :string(255)
#  ip                              :string(255)
#  confirmation_token              :string(255)
#  confirmed_at                    :datetime
#  confirmation_sent_at            :datetime
#  unconfirmed_email               :string(255)
#  created_at                      :datetime
#  updated_at                      :datetime
#  city                            :string(255)
#  gender                          :boolean          default(FALSE)
#  country                         :string(10)
#  state                           :string(50)
#  authentication_token            :string(255)
#  ref_initial                     :string(255)
#  ref_immediate                   :string(255)
#  otp                             :string(255)
#  otp_valid_till                  :datetime
#  otp_attempts                    :integer
#  otp_last_attempt                :datetime
#  total_credits                   :integer
#  note                            :string(255)
#  license_verified                :boolean          default(FALSE)
#  blacklist_reason                :string(255)
#  blacklist_auth                  :string(255)
#  authentication_token_valid_till :string(255)
#  medium                          :string(20)
#  license_status                  :integer          default(0)
#  license_approver_id             :integer
#  license_notes                   :string(256)
#  license_validity                :date
#  wallet_total_amount             :integer
#  city_id                         :integer
#  license_updated_at              :datetime
#  card_saved                      :boolean          default(FALSE)
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email)
#  index_users_on_medium                (medium)
#  index_users_on_ref_immediate         (ref_immediate)
#  index_users_on_ref_initial           (ref_initial)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
