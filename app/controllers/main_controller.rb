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
		ends
	end


	def index
		if session[:starts] && session[:ends]
			redirect_to action: "book"
		end
	end


	def list

	end
	
	

	def payment(booking,todo)

		case todo

		when 

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


	def settings(user)

		#check the session and pull the user details
		#edit the user details
		#more about  UI play

	end


end
