require "open-uri"
class User < ActiveRecord::Base
  
  has_many :image, :as => :imageable, dependent: :destroy
  has_many :bookings
  has_many :credits
  has_many :wallets
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable 
  devise :database_authenticatable, :registerable, 
         :recoverable, :rememberable, :trackable, :validatable, 
         :omniauthable, :omniauth_providers => [:facebook, :google_oauth2]
	
	attr_writer :signup
	attr_writer :profile
	attr_writer :license_check
	
	validates :email, presence: true
  validates :email, uniqueness: true
  validates :name, :phone, :dob, presence: true, if: Proc.new {|u| u.signup?}
  validates :phone, uniqueness: true, if: Proc.new {|u| u.signup?}
  validates :license, presence: true, if: Proc.new {|u| u.license_check?}
  validates :license, uniqueness: true, if: Proc.new {|u| u.license_check? && !u.license.blank?}
  validates :phone, numericality: {only_integer: true}, if: Proc.new {|u| u.profile? && !u.phone.blank?}
  validates :pincode, numericality: {only_integer: true}, if: Proc.new {|u| !u.pincode.blank?}
  validates :phone, length: {is: 10, message: 'only indian mobile numbers without +91/091' }, if: Proc.new {|u| u.profile? && !u.phone.blank?}
  validates :pincode, length: {is: 6, message: 'should be of 6 digits'}, if: Proc.new {|u| !u.pincode.blank?}
  validate :check_dob
  
  after_create :send_welcome_mail
  before_create :before_create_tasks
	before_validation :before_validation_tasks
	
	def admin?
		return self.role == 10
	end
	
	def check_details
		return !self.name.blank? && !self.phone.blank? && !self.dob.blank?
	end
	
	def check_license
		return self.license_pic
	end
	
  def check_dob
  	errors.add(:dob, "can't be less than #{CommonHelper::MIN_AGE} years") if !self.dob.blank? && (self.dob.to_datetime > (Time.zone.now - CommonHelper::MIN_AGE.years))
  end
  
	def encoded_id
		CommonHelper.encode('user', self.id)
	end

  def fleet?
		return self.role >= 5
	end
	
	def get_bookings(action, page=0)
  	sql, order = case action
  	when 'live' then ["(jsi IS NOT NULL OR (jsi IS NULL AND status > 0)) AND starts <= '#{Time.zone.now.to_s(:db)}' AND returned_at IS NULL AND ends >= '#{Time.zone.now.to_s(:db)}' AND status < 8", 'starts ASC']
  	when 'future' then ["(jsi IS NOT NULL OR (jsi IS NULL AND status > 0)) AND starts > '#{Time.zone.now.to_s(:db)}' AND status < 8", 'starts ASC']
  	when 'completed' then ["(jsi IS NOT NULL OR (jsi IS NULL AND status > 0)) AND returned_at IS NOT NULL AND returned_at < '#{Time.zone.now.to_s(:db)}' AND status < 8", 'id DESC']
  	when 'cancelled' then ["status > 8", 'id DESC']
  	when 'unfinished' then ["jsi IS NULL AND status = 0 AND starts > '#{Time.zone.now.to_s(:db)}'", 'id DESC']
  	when 'wallet_frozen' then ["(jsi IS NOT NULL OR (jsi IS NULL AND status > 0)) AND 
  		((starts >= '#{Time.zone.now.to_s(:db)}' AND starts <= '#{(Time.zone.now+CommonHelper::WALLET_FREEZE_START.hours).to_s(:db)}') OR (ends < '#{Time.zone.now.to_s(:db)}' AND ends >= '#{(Time.zone.now-CommonHelper::WALLET_FREEZE_END.hours).to_s(:db)}')) 
  		AND status < 8 and settled!=1 and insufficient_deposit!=1", 'starts ASC']
  	end

  	if Rails.env == 'production'
  		return Booking.find_by_sql("SELECT * FROM bookings WHERE user_id = #{self.id} AND #{sql} ORDER BY #{order}")
  	else
  		if self.support?
        return Booking.find_by_sql("SELECT * FROM bookings WHERE #{sql} ORDER BY #{order}")
      else
	  		return Booking.find_by_sql("SELECT * FROM bookings WHERE user_id = #{self.id} AND #{sql} ORDER BY #{order}")
	  	end
  	end
  end
  
  def is_blacklisted?
    if self.status == CommonHelper::BLACKLISTED_STATUS
      return true
    else 
      return false
    end
  end

  def is_underage?
  	if ((Time.now.to_i - self.dob.to_datetime.to_i) < 21.years.to_i)
  		return true
  	else
  		return false
  	end
  end
  
  def license_check?
    @license_check
  end
  
  def license_pic
		return Image.find(:first, :conditions => ["imageable_id = ? AND imageable_type = 'License'", self.id])
	end
	
	def profile?
    @profile || @signup
  end
  
	def self.find_for_oauth(auth, signed_in=nil, ref_initial=nil, ref_immediate=nil)
  	is_new = 0
  	case auth.provider
  	when 'facebook'
  		return [0, nil] if auth.info.email.blank?
  		user = User.where(:email => auth.info.email).first
  		unless user
  			is_new = 1
	  		user = User.create!(email: auth.info.email, ref_initial: ref_initial, ref_immediate: ref_immediate, password: Devise.friendly_token.first(12))
	  	end
  		img = user.image
  		if user.name.blank? || user.city.blank? || user.dob.blank? || !img || user.encrypted_password.blank?
  			options = {:access_token => auth['credentials']['token']}
				fql = Fql.execute("SELECT birthday_date, sex, pic_big FROM user WHERE uid = me()", options)[0]
  			user.name = auth.info.name if user.name.blank?
  			if !auth.extra.raw_info.location.blank?
					if user.city.blank?
						if auth.extra.raw_info.location.name.include?(',')
							user.city = auth.extra.raw_info.location.name.split(',')[0].strip
							if user.country.blank? && Country.find_country_by_name(auth.extra.raw_info.location.name.split(',')[1].strip.downcase)
	 							user.country = Country.find_country_by_name(auth.extra.raw_info.location.name.split(',')[1].strip.downcase).alpha2
	 						end
						else
							user.city = auth.extra.raw_info.location.name
						end
					end
					user.state = auth.extra.raw_info.location.state if user.state.blank?
					if user.country.blank? && Country.find_country_by_name(auth.extra.raw_info.location.country)
						user.country = Country.find_country_by_name(auth.extra.raw_info.location.country).alpha2
					end
				end
 				user.dob = Date.parse(fql['birthday_date']) if user.dob.blank? && !fql['birthday_date'].blank?
  			if !fql['sex'].blank?
  				if fql['sex'].downcase == 'male'
  					user.gender = 0
  				else
  					user.gender = 1
  				end
  			end
 				user.password = Devise.friendly_token.first(12) if user.encrypted_password.blank?
 				if !user.phone.blank?
	 				user.phone = user.phone.to_i.to_s
	 				user.phone = nil if user.phone.length != 10
	 			end
  			user.save!
  			if !img
					io = nil
					begin
						io = open(fql['pic_big'])
						if io
							def io.original_filename; base_uri.path.split('/').last; end
							io.original_filename.blank? ? nil : io
						end
					rescue
					end
					img = Image.create(:imageable_id => user.id, :imageable_type => 'User') if io
				end
	  	end
		when 'google_oauth2'
			access_token = auth["credentials"]["token"]
			data = auth.info
		  raw  = auth.extra.raw_info
		  user = User.where(:email => data["email"]).first
		  unless user
  			is_new = 1
	  		user = User.create(email: data["email"], ref_initial: ref_initial, ref_immediate: ref_immediate, password: Devise.friendly_token.first(12))
  	  end
		  if user.name.blank? || user.dob.blank? || user.encrypted_password.blank?
		    user.name = data["name"] if user.name.blank?
		    user.dob = Date.parse(raw["birthday"]) if user.dob.blank? && !raw["birthday"].blank?
		    user.password = Devise.friendly_token.first(12) if user.encrypted_password.blank?
				if !raw["gender"].blank?
					if raw["gender"].downcase == 'male'
						user.gender = 0
					else
						user.gender = 1
					end
		    end
			  user.save!
			end
		end
		return [is_new, user]
	end
	
  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end
  
  def signup?
    @signup
  end
  
 	def support?
		return self.role.to_i > 5
	end
	
	def update_credits
		sum = 0
		credits.each do |cr|
			if cr.action
				sum += cr.amount 
			else
				sum -= cr.amount 
			end
		end
		self.update_column(:total_credits, sum)
	end

	def generate_otp
		self.otp = rand(100000..999999)
		self.otp_valid_till = Time.now + 2.hours
		self.otp_attempts = 0 
		save!
	end

	def otp_requested?
		otp.to_s.length == 6 && Time.now < otp_valid_till
	end

	def reset_with_otp(ot_pass, new_pass)
		if otp_attempts < 3
			if otp_requested?
				if otp == ot_pass 
					self.password = self.password_confirmation = new_pass
					save
				else
					self.errors.add(base: "Reset attempts exceeded, contact support.")
				end
			else
				self.errors.add(base: "Token expired, please generate new one.")
			end
		else
			self.errors.add(base: "Token expired, please generate new one.")
		end
	end

  def before_create_tasks
  	#self.confirmed_at = Time.now + 2.hours
  end
  
  def before_validation_tasks
  	if !self.country.blank? && self.country != 'IN'
  		self.state = nil
  		self.city = nil
  		self.pincode = nil
  	end
  end

  def valid_otp_length?
  	otp.to_s.length == 6
  end

  def valid_otp_time?
  	otp_valid_till && otp_valid_till > Time.now
  end

	def snapshot_end
		Time.zone.now + CommonHelper::WALLET_SNAPSHOT.days
	end

	def snapshot_bookings(time=snapshot_end)
		get_bookings('live') | upcoming_bookings(time)
	end

	def upcoming_bookings(end_time=snapshot_end)
		starting = "starts > '#{Time.zone.now.to_s(:db)}' AND starts < '#{(end_time + CommonHelper::WALLET_FREEZE_START.hours).to_s(:db)}'AND status < 8"
		ending = "ends > '#{(Time.zone.now - CommonHelper::WALLET_FREEZE_END.hours).to_s(:db)}' AND ends < '#{end_time.to_s(:db)}'AND status < 8"
		Booking.find_by_sql("SELECT * FROM bookings WHERE user_id = #{self.id} AND (jsi IS NOT NULL OR (jsi IS NULL AND status > 0)) AND ((#{starting}) OR (#{ending})) ORDER BY ends ASC")
	end

	def calculate_wallet_total_amount
		self.update_column(:wallet_total_amount, wallets.collect{|wallet| wallet.credit ? wallet.amount : -wallet.amount}.sum)
	end
  	
  	def wallet_total_amount
  		calculate_wallet_total_amount if read_attribute(:wallet_total_amount).nil?
  		read_attribute(:wallet_total_amount).to_i
  	end

  	def wallet_frozen_bookings
  		get_bookings('live') | get_bookings('wallet_frozen')
  	end

  	def wallet_frozen_amount
  		wallet_frozen_bookings.reject{|b| b.wallet_security_payment.nil?}.collect(&:security_amount).sum
	end

	def wallet_available_amount
		(wallet_total_amount + wallet_frozen_amount)
	end

	def wallet_available_on_time(ends,req_booking)
		return wallet_total_amount if ends <= Time.now
		wallet_amount = wallet_available_amount
		snapshot_bookings(ends).each do |booking|
			wallet_amount -= booking.pricing.mode::SECURITY if !booking.hold? || req_booking.wallet_overlaps?(booking)
		end
		return (wallet_amount < 0) ? 0 : wallet_amount
	end

	def unsafe_booking?(booking)
		if booking.defer_allowed? || booking.security_charge.nil?
			return booking.security_amount_remaining > 0
		else
			return booking.insufficient_deposit
		end
	end

	def unsafe_bookings
		wallet_snapshot[:unsafe].select{|b| b.starts>Time.now}	
	end

	def wallet_snapshot(snap_start= Time.now, snap_end= snap_start+CommonHelper::WALLET_SNAPSHOT.days)
		amount = wallet_available_amount
		snapshot={starts: snap_start, ends: snap_end, amount: amount, bookings: [], unsafe: []}
		upcoming_bookings.each do |booking|
			#TODO handle no car case
			next if !CommonHelper::UPCOMING_STATUSES.include?(booking.status)
			impact = booking.wallet_impact
			snapshot[:unsafe] << impact[:booking] if (booking.wallet_security_payment.nil? && amount<booking.security_amount)
			amount += impact[:amount]
			snapshot[:bookings] << impact
		end
		snapshot
	end 

	def send_welcome_mail
		if rand(100) < 80 #&& self.name_was.nil? && self.name_changed?
			BookingMailer.welcome(self).deliver
		end
	end
	
	private :before_create_tasks, :before_validation_tasks, :valid_otp_length?
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
