require "open-uri"
class User < ActiveRecord::Base
  
  has_one :image, :as => :imageable, dependent: :destroy
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable 
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, 
         :omniauthable, :omniauth_providers => [:facebook, :google_oauth2]
	
	validates :email, presence: true
  validates :email, uniqueness: true
  
  def self.find_for_oauth(auth, signed_in=nil)
  	case auth.provider
  	when 'facebook'
  		user = User.where(:email => auth.info.email).first
  		user = User.create(email:auth.info.email) unless user
  		img = user.image
  		if user.name.blank? || user.city.blank? || user.dob.blank? || !img
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
		  user = User.create(email:data["email"]) unless user
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
		return user
	end
	
  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end
  
end
