require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
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
