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
	
	validates :email, presence: true
  validates :email, uniqueness: true
  validates :name, :phone, :dob, presence: true, if: Proc.new {|u| u.signup?}
  validates :phone, uniqueness: true, if: Proc.new {|u| u.signup?}
  validates :phone, numericality: {only_integer: true}, if: Proc.new {|u| !u.phone.blank?}
  validates :pincode, numericality: {only_integer: true}, if: Proc.new {|u| !u.pincode.blank?}
  validates :phone, length: {is: 10, message: 'only indian mobile numbers without +91/091' }, if: Proc.new {|u| !u.phone.blank?}
  validates :pincode, length: {is: 6}, if: Proc.new {|u| !u.pincode.blank?}
  validate :check_dob
  

  def check_dob
  	errors.add(:dob, "can't be less than 23 years") if !self.dob.blank? && self.dob > (Time.zone.now - 23.years)
  end
  
  def get_bookings(action, page=0)
  	sql = case action
  	when 'live' then "starts <= '#{Time.zone.now.to_s(:db)}' AND ends >= '#{Time.zone.now.to_s(:db)}' AND status < 5"
  	when 'future' then "starts > '#{Time.zone.now.to_s(:db)}' AND status < 5"
  	when 'completed' then "ends < '#{Time.zone.now.to_s(:db)}' AND status <= 5"
  	when 'cancelled' then "status > 5"
  	end
  	return Booking.find_by_sql("SELECT * FROM bookings WHERE " + sql + " ORDER BY id DESC LIMIT 10 OFFSET #{page*10}")
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
  			user.city = auth.extra.raw_info.location.name if user.city.blank?
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
  
end
