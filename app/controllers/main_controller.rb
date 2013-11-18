class MainController < ApplicationController


	def book

	end

	def index

	end

	def list

	end
	

	def payment

	end

	def search
		booking = params[:booking]
		status = Inventory.check(booking[:cargroup_id],booking[:location_id],booking[:starts],booking[:ends])
		if status != 2 && booking[:cargroup_id] && booking[:location_id]
			if status == 0
				flash[:notice] = "the car is not present"
			else
				flash[:notice] = "the is car is not available"
			end
			redirect_to root_path
		end
		session[:starts] = booking[:starts]
		session[:ends] = booking[:ends]
		session[:cargroup_id] = booking[:cargroup_id] if !booking[:cargroup_id].blank?
		session[:location_id] = booking[:location_id] if !booking[:location_id].blank?

		@cars = Inventory.get_available_cars(booking)
	end


end
