require "open-uri"
class User < ActiveRecord::Base
  
  has_one :image, :as => :imageable, dependent: :destroy
  has_many :bookings
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable 
  devise :database_authenticatable, :registerable, :confirmable, 
         :recoverable, :rememberable, :trackable, :validatable, 
         :omniauthable, :omniauth_providers => [:facebook, :google_oauth2]
	
	attr_writer :signup
	attr_writer :license_check
	
	validates :email, presence: true
  validates :email, uniqueness: true
  validates :name, :phone, :dob, presence: true, if: Proc.new {|u| u.signup?}
  validates :phone, uniqueness: true, if: Proc.new {|u| u.signup?}
  validates :license, presence: true, if: Proc.new {|u| u.license_check?}
  validates :license, uniqueness: true, if: Proc.new {|u| u.license_check? && !u.license.blank?}
  validates :phone, numericality: {only_integer: true}, if: Proc.new {|u| !u.phone.blank?}
  validates :pincode, numericality: {only_integer: true}, if: Proc.new {|u| !u.pincode.blank?}
  validates :phone, length: {is: 10, message: 'only indian mobile numbers without +91/091' }, if: Proc.new {|u| !u.phone.blank?}
  validates :pincode, length: {is: 6, message: 'should be of 6 digits'}, if: Proc.new {|u| !u.pincode.blank?}
  validate :check_dob
  
	before_validation :before_validation_tasks
	
	def admin?
		return self.role == 10
	end
	
	def check_details
		return !self.name.blank? && !self.phone.blank? && !self.dob.blank?
	end
	
	def check_license
		return (!self.license.blank? || self.license_pic)
	end
	
  def check_dob
  	errors.add(:dob, "can't be less than 23 years") if !self.dob.blank? && (self.dob.to_datetime > (Time.zone.now - 23.years))
  end
  
  def fleet?
		return self.role >= 5
	end
	
	def get_bookings(action, page=0)
  	sql, order = case action
  	when 'live' then ["starts <= '#{Time.zone.now.to_s(:db)}' AND ends >= '#{Time.zone.now.to_s(:db)}' AND status < 5", 'starts ASC']
  	when 'future' then ["starts > '#{Time.zone.now.to_s(:db)}' AND status < 5", 'starts ASC']
  	when 'completed' then ["ends < '#{Time.zone.now.to_s(:db)}' AND status <= 5", 'id DESC']
  	when 'cancelled' then ["status > 5", 'id DESC']
  	end
  	
  	if true #Rails.env == 'production'
  		return Booking.find_by_sql("SELECT * FROM bookings WHERE user_id = #{self.id} AND #{sql} ORDER BY #{order} LIMIT 10 OFFSET #{page*10}")
  	else
  		return Booking.find_by_sql("SELECT * FROM bookings WHERE #{sql} ORDER BY #{order} LIMIT 10 OFFSET #{page*10}")
  	end
  end
  
  def license_check?
    @license_check
  end
  
  def license_pic
		return Image.find(:first, :conditions => ["imageable_id = ? AND imageable_type = 'License'", self.id])
	end
	
	def self.find_for_oauth(auth, signed_in=nil)
  	is_new = 0
  	case auth.provider
  	when 'facebook'
  		user = User.where(:email => auth.info.email).first
  		unless user
  			is_new = 1
	  		user = User.create(email:auth.info.email)
	  	end
  		img = user.image
  		if user.name.blank? || user.city.blank? || user.dob.blank? || !img || user.encrypted_password.blank?
  			options = {:access_token => auth['credentials']['token']}
				fql = Fql.execute("SELECT birthday_date, sex, pic_big FROM user WHERE uid = me()", options)[0]
  			user.name = auth.info.name if user.name.blank?
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
 				user.dob = Date.parse(fql['birthday_date']) if user.dob.blank? && !fql['birthday_date'].blank?
  			if !fql['sex'].blank?
  				if fql['sex'].downcase == 'male'
  					user.gender = 0
  				else
  					user.gender = 1
  				end
  			end
 				user.password = Devise.friendly_token.first(12) if user.encrypted_password.blank?
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
			data = access_token.info
		  raw  = access_token.extra.raw_info
		  user = User.where(:email => data["email"]).first
		  unless user
  			is_new = 1
	  		user = User.create(email:data["email"])
	  	end
		  if user.name.blank? || user.dob.blank?
		    user.name = data["name"] if user.name.blank?
		    user.dob = raw["birthday"] if user.dob.blank?
		    user.save!
		  end
		  if !user.image
  			io = nil
		  	begin
					io = open(data["image"])
					if io
						def io.original_filename; base_uri.path.split('/').last; end
						io.original_filename.blank? ? nil : io
					end
				rescue
				end
	  		img = Image.create(:imageable_id => user.id, :imageable_type => 'User') if io
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
  
  private
  
  def before_validation_tasks
  	if !self.country.blank? && self.country != 'IN'
  		self.state = nil
  		self.city = nil
  		self.pincode = nil
  	end
  end
  
end
