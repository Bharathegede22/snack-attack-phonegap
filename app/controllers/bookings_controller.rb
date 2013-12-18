class BookingsController < ApplicationController
	
	def index
		render layout: 'users'
	end
	
	def invoice
		str,id = CommonHelper.decode(params[:id])
		if !str.blank? && str == 'booking'
			@booking = Booking.find(id)
			render layout: 'plain'
		else
			render_404
		end
	end
	
	def search
		@meta_title = "Zoom - Car Hire in Bangalore"
		@meta_description = "Enjoy the Freedom of Four Wheels with self-drive car hire by the hour or by the day. Now in Bangalore!"
		@meta_keywords = "car hire, car rental, car rent, car sharing, car share, shared car, car club, rental car, car-sharing, hire car, renting a car, bangalore, bangalore car hire, bangalore car rental, bangalore car rent, bangalore car sharing, bangalore car share, bangalore car club, bangalore rental car, bangalore car-sharing, bangalore hire car, bagalore renting a car, India, Indian, Indian car-sharing, India car-sharing, Indian car-share, India car-share, India car club, Indian car club, India car sharing, Indian car, Zoomcar, Zoom car, travel india, travel bangalore, explore india, explore bangalore, travel, explore, self-drive, self drive, self-drive bangalore, self drive bangalore"
		@canonical = "https://www.zoomcar.in/search"
	end
	
	def show
		str,id = CommonHelper.decode(params[:id])
		if !str.blank? && str == 'booking'
			@booking = Booking.find(id)
			render layout: 'users'
		else
			render_404
		end
	end
	
	def widget
		render json: {html: render_to_string('widget.haml')}
	end
	
end
