class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable 

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, 
         :omniauthable, :omniauth_providers => [:facebook, :google_oauth2]

   #check whether the user already signed up or it will create a new user
  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
	  user = User.where(:email => auth.info.email).first
	  unless user
	    user = User.create(email:auth.info.email,name:auth.info.name,city:auth.extra.raw_info.location.name,
             dob:auth.extra.raw_info.birthday,img_url:auth.info.image,password:Devise.friendly_token[0,20])
	  end
	  user
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end


  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.info
    raw  = access_token.extra.raw_info
    user = User.where(:email => data["email"]).first

    #location is not available
    unless user
        user = User.create(email: data["email"],name: data["name"],
          dob:raw["birthday"],img_url:data["image"],password: Devise.friendly_token[0,20])
    end
    user
end
end
