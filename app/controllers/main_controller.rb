class MainController < ApplicationController


	def book
		
		session[:cargroup_id] = params[:cargroup_id] if !params[:cargroup_id].blank?
		session[:location_id] = params[:location_id] if !params[:location_id].blank?

		if !user_signed_in?
			redirect_to new_user_session_path
		else
			Inventory.block(session[:cargroup_id],session[:location_id],session[:starts],session[:ends])
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
		if session[:starts] && session[:ends]
			redirect_to action: "book"
		end
	end

	def list

	end
	

	def payment

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


end
