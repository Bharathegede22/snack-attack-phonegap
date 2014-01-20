class MainController < ApplicationController
	
	def about
		@meta_title = "The Zoom Team | www.zoomcar.in"
		@meta_description = "A global team with knowledge and experience in self driven car rental services"
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
			end
			render json: {html: render_to_string("/layouts/calculator/tariff.haml", layout: false)}
		when 'reschedule'
			if request.post?
				@calcar = params[:calcar]
				@calstart = params[:calstart]
				@calend = params[:calend]
				@calret = params[:calret]
				@calmileage = params[:calmileage]
			
				cargroup = Cargroup.find_by_display_name(@calcar)
				if !cargroup
					flash[:error] = 'Unindentified Vehicle.'
				elsif DateTime.parse(params[:calstart]) >= DateTime.parse(params[:calend])
					flash[:error] = 'Pickup and Original Return time are not in increasing order.'
				elsif DateTime.parse(params[:calstart]) >= DateTime.parse(params[:calret])
					flash[:error] = 'Pickup and New Return time are not in increasing order.'
				elsif DateTime.parse(params[:calend]) == DateTime.parse(params[:calret])
					flash[:error] = 'Old and New Return time are same.'
				end
			
				@booking = Booking.new
				@booking.cargroup_id = cargroup.id
				@booking.starts = DateTime.parse(params[:calstart] + ' +05:30')
				@booking.last_ends = DateTime.parse(params[:calend] + ' +05:30')
				@booking.ends = DateTime.parse(params[:calret] + ' +05:30')
				@booking.start_km = 0
				@booking.end_km = params[:calmileage]
			
				@tariff = {}
				if flash[:error].blank?
					@tariff[:late] = @booking.check_late
					@tariff[:extend] = @booking.check_extended
					@tariff[:short] = @booking.check_short
					@tariff[:short_late] = @booking.check_short_late
					@tariff[:early] = @booking.check_early
					@tariff[:mileage] = @booking.check_mileage
					@tariff[:mileage_fee] = @booking.check_mileage_charge
					@tariff[:cancel] = @booking.handle_cancellation
					@tariff[:cancel_late] = @booking.handle_cancellation_late
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
	
	def eligibility
		@meta_title = "Is Zoom For Me? | Eligibility Policy | Zoomcar.in"
		@meta_description = "The eligibility policy for using Zoom's cars.  Members must be 23 years with valid driving license.  Payment is by credit or debit card only"
		@meta_keywords = "zoomcar eligibility policy"
		@canonical = "http://www.zoomcar.in/eligibility"
	end
	
	def faq
		@meta_title = "Zoom Frequently Asked Questions (FAQs) | Zoomcar.in"
		@meta_description = "Have questions about Zoom?  They might already be answered here!"
		@meta_keywords = "zoomcar faqs"
		@canonical = "http://www.zoomcar.in/faq"
	end
	
	def fees
		@meta_title = "Zoom Fee Policy | Zoomcar.in"
		@meta_description = "Zoom fee policy for returning vehicle late, returning vehicle to wrong location, traffic and parking violations, key not returned at end of reservation, accident or other incident, & Zoom rule violations"
		@meta_keywords = "zoomcar fees policy"
		@canonical = "http://www.zoomcar.in/fees"
	end
	
	def holidays
		@meta_title = "List of Holidays | Zoomcar.in"
		@meta_description = "Zoom off on Holidays "
		@meta_keywords = "zoomcar holidays"
		@canonical = "http://www.zoomcar.in/holidays"
	end
	
	def howtozoom
		@meta_title = "8 Steps To Be A Better Zoom Member | Zoomcar.in"
		@meta_description = "Help us build the Zoom community by following these 8 easy steps"
		@meta_keywords = "zoomcar member"
		@canonical = "http://www.zoomcar.in/howtozoom"
	end
	
	def index
		@meta_title = "Self Drive Car Rental In Bangalore | Find Cars And Book Online | Zoomcar.in"
		@meta_description = "Self-drive car hire in Bangalore. Enjoy the Freedom of Four Wheels by renting a car by the hour or by the day.  All-inclusive tariff covers fuel, insurance & taxes"
		@meta_keywords = "zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
		@canonical = "http://www.zoomcar.in"
		render layout: false
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
		
	end
	
	def member
		@meta_title = "Zoom Member Agreement | Zoomcar.in"
		@meta_description = "The Zoom Member agreement is the contract that governs the use of Zoom vehicles"
		@meta_keywords = "zoomcar Member agreement"
		@canonical = "http://www.zoomcar.in/member"
	end
	
	def outstation
		@meta_title = "Zooming Outstation | Zoomcar.in"
		@meta_description = "Zoom guidelines for a safe outstation experience"
		@meta_keywords = "zoomcar, zoom, safety"
		@canonical = "http://www.zoomcar.in/outstation"
	end
	
	def privacy
		@meta_title = "Privacy Policy | Zoomcar.in"
		@meta_description = "Privacy policy for using zoom"
		@meta_keywords = "zoomcar, zoom, safety"
		@canonical = "http://www.zoomcar.in/privacy"
	end
	
	def reva
		@meta_title = "Mahindra Reva E2O | www.zoomcar.in"
		@meta_description = "Zoom in India's only electric car"
		@meta_keywords = "zoomcar mahindra reva e2o"
		@canonical = "http://www.zoomcar.in/reva"
	end
	
	def safety
		@meta_title = "Zoom Safety | Zoomcar.in"
		@meta_description = "Zoom guidelines for a safe zooming experience"
		@meta_keywords = "zoomcar, zoom, safety"
		@canonical = "http://www.zoomcar.in/safety"
	end
	
	def seo
		str,id = CommonHelper.decode(params[:id].split('_').last.strip)
		case str
		when 'attraction'
			@object = Attraction.find(id)
		end
		@meta_title = @object.meta_title
		@meta_description = @object.meta_description
		@meta_keywords = @object.meta_keywords
		@canonical = @object.link
		render "/seo/" + str
	end
	
	def tariff
		@meta_title = "Zoom Car Hire Tariffs In Bangalore | Zoomcar.in"
		@meta_description = "Zoom offers the simplest, easiest car-hire tariff in Bangalore.  See prices and what is included.  Check frequently for special offers and discounts on renting a car in Bangalore!"
		@meta_keywords = "zoomcar hire tariffs"
		@canonical = "http://www.zoomcar.in/tariff"
		@cargroup = Cargroup.list
	end
	
end
