class MainController < ApplicationController
	
	def about
		@meta_title = "About ZoomCar Team | Online Self Drive Car In Bangalore"
		@meta_description = "Read about ZoomCar's self drive car team. Highly qualified professionals with knowledge and experience in self driven car rental services"
		@meta_keywords = "zoomcar team"
		@canonical = "http://www.zoomcar.in/about"
	end
	
	def calculator
		@action = params[:id]
		case @action
		when 'tariff'
			if request.post?
				@car = Cargroup.find_by_id(params[:car]) if !params[:car].blank?
				@starts = Time.zone.parse(params[:starts]) if !params[:starts].blank?
				@ends = Time.zone.parse(params[:ends]) if !params[:ends].blank?
				@kms = params[:kms]
				
				if @car.blank?
					flash[:error] = 'Unindentified Vehicle.'
				elsif @starts >= @ends
					flash[:error] = 'Pickup and Return time are not in increasing order.'
				end
				
				@tariff = @car.check_fare(@starts, @ends) if flash[:error].blank?
			elsif !params[:process].blank? && params[:process] == 'checkout' && !session[:book].blank? && !session[:book][:starts].blank? && !session[:book][:ends].blank? && !session[:book][:car].blank?
				@car = Cargroup.find_by_id(session[:book][:car])
				@starts = Time.zone.parse(session[:book][:starts])
				@ends = Time.zone.parse(session[:book][:ends])
				@tariff = @car.check_fare(@starts, @ends) if flash[:error].blank?
			end
			render json: {html: render_to_string("/layouts/calculator/tariff.haml", layout: false)}
		when 'reschedule'
			if request.post?
				@car = Cargroup.find_by_id(params[:car]) if !params[:car].blank?
				@starts = Time.zone.parse(params[:starts]) if !params[:starts].blank?
				@ends = Time.zone.parse(params[:ends]) if !params[:ends].blank?
				@newends = Time.zone.parse(params[:newends]) if !params[:newends].blank?
				@kms = params[:kms]
				
				if @car.blank?
					flash[:error] = 'Unindentified Vehicle.'
				elsif @starts >= @ends
					flash[:error] = 'Pickup and Original Return time are not in increasing order.'
				elsif @starts >= @newends
					flash[:error] = 'Pickup and New Return time are not in increasing order.'
				end
				
				if flash[:error].blank?
					@tariff = {}
					if @ends > @newends
						@tariff[:reschedule] = @car.check_reschedule(@starts, @starts, @newends, @ends)
					else
						@tariff[:reschedule] = @car.check_reschedule(@starts, @starts, @ends, @newends)
					end
					@tariff[:late] = @car.check_late(@ends, @newends)
					@tariff[:old] = @car.check_fare(@starts, @ends)
					@tariff[:new] = @car.check_fare(@starts, @newends)
				end
			end
			render json: {html: render_to_string("/layouts/calculator/reschedule.haml", layout: false)}
		end
	end
	
	def careers
		@meta_title = "The Zoom Careers | www.zoomcar.in"
		@meta_description = "Zoom Carrers"
		@meta_keywords = "zoomcar careers"
		@canonical = "http://www.zoomcar.in/careers"
	end
	
	def city
		@meta_title = @city.meta_title('attractions')
		@meta_description = @city.meta_description('attractions')
		@meta_keywords = @city.meta_keywords('attractions')
		@canonical = @city.link('attractions')
	end
	
	def eligibility
		@meta_title = "Is Zoom Car For Me? Eligibility Policy | Zoomcar.in"
		@meta_description = "Read the eligibility policy from ZoomCar. Members must be #{CommonHelper::MIN_AGE} years with driving license and member should be able to pay by credit or debit card"
		@meta_keywords = "zoomcar eligibility policy"
		@canonical = "http://www.zoomcar.in/eligibility"
		@header = 'policy'
	end
	
	def faq
		@meta_title = "ZoomCar Frequently Asked Questions (FAQs) | Zoomcar.in"
		@meta_description = "Read answers about ZoomCar to the most frequently asked questions on our FAQ page"
		@meta_keywords = "zoomcar faqs"
		@canonical = "http://www.zoomcar.in/faq"
		@header = 'help'
	end
	
	def fees
		@meta_title = "ZoomCar Fees Policy | Zoomcar.in"
		@meta_description = "Read ZoomCar fees policy for any returning vehicle late, returning vehicle to wrong location, traffic and parking violations, key not returned at end of reservation, accident & Zoom rule violations" 
    @meta_keywords = "zoomcar fees policy"
		@canonical = "http://www.zoomcar.in/fees"
		@header = 'policy'
	end
	
	def get_locations_map
		@city = City.find_by_id(params[:id]) if !params[:id].blank?
		@zoom = params[:zoom] if !params[:zoom].blank?
		render json: {html: render_to_string("locations_map", layout: false)}
	end
	
	def handover
		@meta_title = "Things to know before you Zoom off | www.zoomcar.in"
		@meta_description = "Zoom Handover"
		@meta_keywords = "zoomcar handover"
		@canonical = "http://www.zoomcar.in/handover"
		@header = 'help'
	end
	
	def holidays
		@meta_title = "List of Holidays | Zoomcar.in"
		@meta_description = "Zoom off on Holidays "
		@meta_keywords = "zoomcar holidays"
		@canonical = "http://www.zoomcar.in/holidays"
	end
	
	def homepage
		@meta_title = "Self Drive Cars Rental In Bangalore | Join Online, Book A Car & Drive | Zoomcar.in"
		@meta_description = "Book a self-driven car online. Self driving car rental made easy like never before, simply join us for renting a car by the hour or day. Includes fuel, insurance & taxes"
		@meta_keywords = "zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
		@canonical = "http://www.zoomcar.in"
		@header = 'homepage'
		@noindex = true
		#expires_in 1.months, :public => true, 'max-stale' => 0 #if Rails.env == 'production'
	end
	
	def howtozoom
		@meta_title = "Self Drive Cars Rental In Bangalore | Join Online, Book A Car & Drive | Zoomcar.in"
		@meta_description = "Read how to be a better ZoomCar Member"
		@meta_keywords = "zoomcar member"
		@canonical = "http://www.zoomcar.in/howtozoom"
		@header = 'help'
	end
	
	def index
		@meta_title = @city.meta_title
		@meta_description = @city.meta_description
		@meta_keywords = @city.meta_keywords
		@canonical = @city.link
		@header = 'homepage'
		#expires_in 1.months, :public => true, 'max-stale' => 0 #if Rails.env == 'production'
	end
	
	def job
		str,id = CommonHelper.decode(params[:id].strip)
		if str == 'job'
			@job = Job.find(id)
			@meta_title = @job.meta_title
			@meta_description = @job.meta_description
			@meta_keywords = @job.meta_keywords
			@canonical = @job.link
		end
	end
	
	def join
		head :moved_permanently, :location => "/users/sign_in" and return
	end
	
	def map
		render json: {html: render_to_string('/main/map.haml', :layout => false)}
	end
	
	def member
		@meta_title = "ZoomCar Member Agreement | Zoomcar.in"
		@meta_description = "Read ZoomCar Member agreement is a contract and governs the relationships, rights, and obligations between ZoomCar India Private Limited and the Member"
		@meta_keywords = "zoomcar Member agreemen"
		@canonical = "http://www.zoomcar.in/member"
		@header = 'policy'
	end
	
	def offers
		@meta_title = "Zoom for Less in Bangalore | www.zoomcar.in"
		@meta_description = "Offers running in Bangalore on Zoom"
		@meta_keywords = "zoomcar offers"
		@canonical = "http://www.zoomcar.in/bangalore/offers"
		@header = 'offers'
	end
	
	def outstation
		@meta_title = "Outstation Car Rental | Rent Self-Drive Car For Outstation Trips"
		@meta_description = "Zoomcar provides local car hire for outstation trips outside Karnataka state.  Book outstation car for Goa, Kerala, Tamil Nadu and Andhra Pradesh at budget prices"
		@meta_keywords = "Outstation car rental, outstation car hire, self drive car for outstation"
		@canonical = "http://www.zoomcar.in/outstation"
		@header = 'help'
	end
	
	def privacy
		@meta_title = "ZoomCar Privacy Policy | Zoomcar.in"
		@meta_description = "Read ZoomCar website usage privacy policy and terms and conditions"
		@meta_keywords = "zoomcar privacy policy"
		@canonical = "http://www.zoomcar.in/privacy"
		@header = 'policy'
	end
	
	def reva
		@meta_title = "Electric Car Hire | Hire Reva For Self-Drive In Bangalore"
		@meta_description = "Zoomcar now offers eco friendly electric car for hire in Bangalore. Now rent Mahindra Reva E20 India's only fully electric car by the hour or by the day."
		@meta_keywords = "electric car hire, hire Reva in Bangalore"
		@canonical = "http://www.zoomcar.in/reva"
		@header = 'help'
	end
	
	def safety
		@meta_title = "Zoom Safety | Zoomcar.in"
		@meta_description = "Zoom guidelines for a safe zooming experience"
		@meta_keywords = "zoomcar, zoom, safety"
		@canonical = "http://www.zoomcar.in/safety"
		@header = 'help'
	end
	
	def tariff
		@meta_title = "ZoomCar Hire Tariffs In Bangalore | Zoomcar.in"
		@meta_description = "ZoomCar offers the simplest, easiest car-hire tariff in Bangalore. Find out what all is included"
		@meta_keywords = "zoomcar hire tariffs"
		@canonical = "http://www.zoomcar.in/tariff"
		@cargroup = Cargroup.list(@city)
		@header = 'tariff'
	end
	
end
