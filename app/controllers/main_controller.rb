class MainController < ApplicationController
	
	def book
		session[:cargroup_id] = params[:cargroup_id] if !params[:cargroup_id].blank?
		session[:location_id] = params[:location_id] if !params[:location_id].blank?

		if !user_signed_in?
			redirect_to new_user_session_path
		else
			Inventory.block(session[:cargroup_id],session[:location_id],session[:starts],session[:ends],0)
			booking = Booking.new
			booking.starts = session[:starts]
			booking.ends = session[:ends]
			booking.cargroup_id = session[:cargroup_id]
			booking.location_id = session[:location_id]
			booking.save
			Booking.select_car(booking)
			session.delete(:cargroup_id)
			session.delete(:location_id)
			session.delete(:starts)
			session.delete(:ends)
		end
	end


	def index
		@meta_title = "Self Drive Car Rental In Bangalore | Find Cars And Book Online | Zoomcar.in"
		@meta_description = "Self-drive car hire in Bangalore. Enjoy the Freedom of Four Wheels by renting a car by the hour or by the day.  All-inclusive tariff covers fuel, insurance & taxes"
		@meta_keywords = "zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
		@canonical = "http://www.zoomcar.in"
		render layout: false
	end


	def list

	end
	
	

	def payment(booking,todo)
	end



	def reschedule(booking)

		status = Inventory.reschedule(booking)

		if status == 2 || status == 4
			flash[:notice]="your booking is successfully rescheduled"
		else
			flash[:notice]="your are not able to reschedule"
		end
	end

	def search
		booking = params[:booking]

		if params[:booking][:cargroup_id] != '' && params[:booking][:location_id] != ''
			status = Inventory.check(booking[:cargroup_id],booking[:location_id],booking[:starts],booking[:ends])
			if status != 2 
				if status == 0
					flash[:notice] = "the car is not present"
				else
					flash[:notice] = "the is car is not available"
				end
				redirect_to root_path
			end
		end
	
		session[:starts] = booking[:starts]
		session[:ends] = booking[:ends]
		session[:cargroup_id] = booking[:cargroup_id] if !booking[:cargroup_id].blank?
		session[:location_id] = booking[:location_id] if !booking[:location_id].blank?

		@cars = Inventory.get_available_cars(booking)
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
	
	def settings(user)

		current_user=User.find(session[:user_id])
		if current_user
			current_user.update(user)
		else
			flash[:notice] = "error in user details updation"
		end

	end


end
