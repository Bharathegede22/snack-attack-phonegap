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
			@calcar = params[:calcar]
			@calstart = params[:calstart]
			@calend = params[:calend]
			@calmileage = params[:calmileage]
		
			rate = [0, 0, 0]

		  cargroup = Cargroup.find_by_display_name(@calcar)
			rate = [cargroup.hourly_fare.to_i, cargroup.daily_fare.to_i, cargroup.excess_kms.to_i] if cargroup

			start_date = DateTime.parse(@calstart + ' +05:30')
			end_date = DateTime.parse(@calend + ' +05:30')
			if rate[0] == 0
				flash[:error] = 'Unindentified Vehicle.'
			elsif start_date >= end_date
				flash[:error] = 'Pickup and Return time are not in increasing order.'
			end
			h = (end_date.to_i - start_date.to_i)/3600
			h += 1 if (end_date.to_i - start_date.to_i) > h*3600
			d = h/24
			h = h - d*24
			flash[:error] = "Sorry, but you can't book for more than 7 days." if d > 7
			if flash[:error].blank?
				@tariff = ['', 0, 0, 0, '', '']
				@tariff[0] << d.to_s + (d == 1 ? ' Day, ' : ' Days, ') if d > 0
				@tariff[0] << h.to_s + (h == 1 ? ' Hour' : ' Hours') if h > 0
				@tariff[0] = @tariff[0].chomp(', ')
				if h > 10
					d += 1
					h = 0
				end
				# Tariff Detail
				@tariff[5] = rate[0].to_s + '/hour, ' + rate[1].to_s + '/day'
				# Extra Fare
				fare_kms = h*40
				fare_kms = 200 if fare_kms > 200
				fare_kms += d*200
				if @calmileage.to_i > 0 && (@calmileage.to_i-fare_kms) > 0
					@tariff[4] = (@calmileage.to_i-fare_kms).to_s + ' Kms @ Rs.' + rate[2].to_s + "/Kms"
					@tariff[3] = (@calmileage.to_i-fare_kms)*rate[2]
				else
					@tariff[4] = 'Rs.' + rate[2].to_s + "/Kms after " + fare_kms.to_s + ' Kms'
				end
				# Daily Fair
				if d > 0
					(0..(d-1)).each do |i|
						wday = (start_date + i.days).wday
						@tariff[1] += rate[1]
						@tariff[2] += rate[1]*0.35 if wday > 0 && wday < 5
					end
				end
				# Hourly Fair
				wday = (start_date + d.days).wday
				@tariff[1] += rate[0]*h
				@tariff[2] += rate[0]*h*0.35 if wday > 0 && wday < 5
			end
			render json: {html: render_to_string("/layouts/calculator/tariff.haml")}
		when 'reschedule'
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
			render json: {html: render_to_string("/layouts/calculator/reschedule.haml")}
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
	
	def showcal
		case params[:id]
		when 'tariff'
			render json: {html: render_to_string('/layouts/calculator/tariff.haml')}
		else
			render json: {html: render_to_string('/layouts/calculator/reschedule.haml')}
		end
	end
	
	def tariff
		@meta_title = "Zoom Car Hire Tariffs In Bangalore | Zoomcar.in"
		@meta_description = "Zoom offers the simplest, easiest car-hire tariff in Bangalore.  See prices and what is included.  Check frequently for special offers and discounts on renting a car in Bangalore!"
		@meta_keywords = "zoomcar hire tariffs"
		@canonical = "http://www.zoomcar.in/tariff"
		@cargroup = Cargroup.list
	end
	
end
