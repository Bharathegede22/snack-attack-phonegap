class MainController < ApplicationController
	
	def about
		@meta_title = "About ZoomCar Team | Online Self Drive Car In #{@city.name}"
		@meta_description = "Read about ZoomCar's self drive car team. Highly qualified professionals with knowledge and experience in self driven car rental services"
		@meta_keywords = "zoomcar team"
		@canonical = "http://www.zoomcar.in/about"
	end
	
	def calculator
		@action = params[:id]
		case @action
		when 'tariff'
			if request.post?
				@booking = Booking.new
				@booking.city_id = @city.id
				@booking.cargroup_id = params[:car] if !params[:car].blank?
				@booking.starts = Time.zone.parse(params[:starts]) if !params[:starts].blank?
				@booking.ends = Time.zone.parse(params[:ends]) if !params[:ends].blank?
				if !params[:kms].blank?
					@kms = params[:kms].to_i
					if @kms > 0
						@booking.start_km = 0
						@booking.end_km = params[:kms].to_i
					end
				end				
				if @booking.cargroup_id.blank?
					flash[:error] = 'Unindentified Vehicle.'
				elsif @booking.starts >= @booking.ends
					flash[:error] = 'Pickup and Return time are not in increasing order.'
				end
			elsif !params[:process].blank? && params[:process] == 'checkout' && !session[:book].blank? && !session[:book][:starts].blank? && !session[:book][:ends].blank? && !session[:book][:car].blank?
				@booking = Booking.new
				@booking.city_id = @city.id
				@booking.cargroup_id = session[:book][:car]
				@booking.starts = Time.zone.parse(session[:book][:starts])
				@booking.ends = Time.zone.parse(session[:book][:ends])
			end
			if @booking && flash[:error].blank?
				@booking.valid?
				@tariff = @booking.get_fare
			end
			render json: {html: render_to_string("/layouts/calculator/tariff.haml", layout: false)}
		when 'reschedule'
			if request.post?
				@booking = Booking.new
				@booking.city_id = @city.id
				@booking.cargroup_id = params[:car] if !params[:car].blank?
				@booking.starts_last = Time.zone.parse(params[:starts]) if !params[:starts].blank?
				@booking.ends_last = Time.zone.parse(params[:ends]) if !params[:ends].blank?
				@booking.starts = Time.zone.parse(params[:newstarts]) if !params[:newstarts].blank?
				@booking.ends = Time.zone.parse(params[:newends]) if !params[:newends].blank?
				@booking.start_km = 0
				@booking.end_km = 0
				
				if !params[:kms].blank?
					@kms = params[:kms].to_i
					if @kms > 0
						@booking.start_km = 0
						@booking.end_km = params[:kms].to_i
					end
				end				
				
				if @booking.cargroup_id.blank?
					flash[:error] = 'Unindentified Vehicle.'
				elsif @booking.starts_last >= @booking.ends_last
					flash[:error] = 'Original Pickup and Return time are not in increasing order.'
				elsif @booking.starts >= @booking.ends
					flash[:error] = 'New Pickup and Return time are not in increasing order.'
				end
				
				if @booking && flash[:error].blank?
					@booking.valid?
					@tariff = {early: {}, extended: {}, late: {}, mod: {}, org: {}, reschedule: {}, short: {}}
					
					booking 							= Booking.new
					booking.city_id 			= @booking.city_id
					booking.cargroup_id 	= @booking.cargroup_id
					booking.starts 				= @booking.starts_last
					booking.ends 					= @booking.ends_last
					booking.status				= 10
					booking.valid?
					
					@tariff[:org] = booking.get_fare
					
					booking.starts 				= @booking.starts
					booking.ends 					= @booking.ends
					
					@tariff[:mod] = booking.get_fare
					
					if @booking.starts_last != @booking.starts
						@tariff[:reschedule] = @booking.get_fare
					else
						if @booking.ends_last < @booking.ends
							@tariff[:extended] = @booking.get_fare
							
							booking.starts				= @booking.starts
							booking.ends 					= @booking.ends_last
							booking.returned_at 	= @booking.ends
							booking.start_km 			= @booking.start_km
							booking.end_km 				= @booking.end_km
							booking.status				= 0
							@tariff[:late] = booking.get_fare
						else
							@tariff[:short] = @booking.get_fare
							
							booking.starts				= @booking.starts
							booking.ends 					= @booking.ends_last
							booking.returned_at 	= @booking.ends
							booking.start_km 			= @booking.start_km
							booking.end_km 				= @booking.end_km
							booking.status				= 0
							@tariff[:early] = booking.get_fare
						end
					end
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
		@canonical = "http://www.zoomcar.in/#{@city.name.downcase}/faq"
		@header = 'help'
		render "/main/pricing/#{@city.pricing_mode}/faq"
	end
	
	def fees
		@meta_title = "ZoomCar Fees Policy | Zoomcar.in"
		@meta_description = "Read ZoomCar fees policy for any returning vehicle late, returning vehicle to wrong location, traffic and parking violations, key not returned at end of reservation, accident & Zoom rule violations" 
    @meta_keywords = "zoomcar fees policy"
		@canonical = "http://www.zoomcar.in/#{@city.name.downcase}/fees"
		@header = 'policy'
		render "/main/pricing/#{@city.pricing_mode}/policy"
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
		@canonical = "http://www.zoomcar.in/#{@city.name.downcase}/holidays"
	end
	
	def homepage
		@meta_title = "Self Drive Cars Rental In #{@city.name} | Join Online, Book A Car & Drive | Zoomcar.in"
		@meta_description = "Book a self-driven car online. Self driving car rental made easy like never before, simply join us for renting a car by the hour or day. Includes fuel, insurance & taxes"
		@meta_keywords = "zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
		@canonical = "http://www.zoomcar.in/#{@city.name.downcase}"
		@header = 'homepage'
		@noindex = true
		#expires_in 1.months, :public => true, 'max-stale' => 0 #if Rails.env == 'production'
	end
	
	def howitworks
		@meta_title = "Self Drive Cars Rental In Bangalore | Join Online, Book A Car & Drive | Zoomcar.in"
		@meta_description = "Know how Zoom works"
		@meta_keywords = "how zoomcar works"
		@canonical = "http://www.zoomcar.in/howitworks"
		@header = 'help'
	end

	def howtozoom
		@meta_title = "Self Drive Cars Rental In #{@city.name} | Join Online, Book A Car & Drive | Zoomcar.in"
		@meta_description = "Read how to be a better ZoomCar Member"
		@meta_keywords = "zoomcar member"
		@canonical = "http://www.zoomcar.in/howtozoom"
		@header = 'help'
	end
	
	def index
		@city = City.lookup('bangalore') if @city.blank?
		redirect_to "/" + @city.name.downcase and return if request.url.split('?').first.split('/').last != @city.name.downcase
		@meta_title = @city.meta_title
		@meta_description = @city.meta_description
		@meta_keywords = @city.meta_keywords
		@header = 'homepage'
		@canonical = @city.link
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
		@meta_title = "Zoom for Less in #{@city.name} | www.zoomcar.in"
		@meta_description = "Offers running in #{@city.name} on Zoom"
		@meta_keywords = "zoomcar offers"
		@canonical = "http://www.zoomcar.in/#{@city.name.downcase}/offers"
		@header = 'offers'
	end
	
	def outstation
		@meta_title = "Outstation Car Rental | Rent Self-Drive Car For Outstation Trips"
		@meta_description = "Zoomcar provides local car hire for outstation trips outside Karnataka and Maharashtra state.  Book outstation car for Goa, Kerala, Tamil Nadu and Andhra Pradesh at budget prices"
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
		@meta_title = "Electric Car Hire | Hire Reva For Self-Drive In #{@city.name}"
		@meta_description = "Zoomcar now offers eco friendly electric car for hire in #{@city.name}. Now rent Mahindra Reva E20 India's only fully electric car by the hour or by the day."
		@meta_keywords = "electric car hire, hire Reva in #{@city.name}"
		@canonical = "http://www.zoomcar.in/reva"
		@header = 'help'
	end
	
	def safety
		@meta_title = "Zoom Safety | Zoomcar.in"
		@meta_description = "Zoom guidelines for a safe zooming experience"
		@meta_keywords = "zoomcar, zoom, safety"
		@canonical = "http://www.zoomcar.in/#{@city.name.downcase}/safety"
		@header = 'help'
	end
	
	def tariff
		@meta_title = "ZoomCar Hire Tariffs In #{@city.name} | Zoomcar.in"
		@meta_description = "ZoomCar offers the simplest, easiest car-hire tariff in #{@city.name}. Find out what all is included"
		@meta_keywords = "zoomcar hire tariffs"
		@canonical = "http://www.zoomcar.in/#{@city.name}/tariff"
		@header = 'tariff'
		render "/main/pricing/#{@city.pricing_mode}/tariff"
	end
	
end
