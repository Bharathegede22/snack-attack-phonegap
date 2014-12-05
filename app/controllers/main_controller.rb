class MainController < ApplicationController
	
	def about
		@meta_title = "About Zoomcar Team | Online Self Drive Car In #{@city.name}"
		@meta_description = "Read about Zoomcar's self drive car team. Highly qualified professionals with knowledge and experience in self driven car rental services"
		@meta_keywords = "zoomcar team"
		@canonical = "http://#{HOSTNAME}/about"
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

          booking             = Booking.new
          booking.city_id     = @booking.city_id
          booking.cargroup_id = @booking.cargroup_id
          booking.starts      = @booking.starts_last
          booking.ends        = @booking.ends_last
          booking.status      = 10
          booking.valid?

          @tariff[:org]       = booking.get_fare

          booking.starts      = @booking.starts
          booking.ends        = @booking.ends

          @tariff[:mod]       = booking.get_fare

          if @booking.starts_last != @booking.starts
            @tariff[:reschedule] = @booking.get_fare
          else
            if @booking.ends_last < @booking.ends
              @tariff[:extended]  = @booking.get_fare

              booking.starts      = @booking.starts
              booking.ends        = @booking.ends_last
              booking.returned_at = @booking.ends
              booking.start_km    = @booking.start_km
              booking.end_km      = @booking.end_km
              booking.status      = 0
              @tariff[:late]      = booking.get_fare
            else
              @tariff[:short] = @booking.get_fare

              booking.starts      = @booking.starts
              booking.ends        = @booking.ends_last
              booking.returned_at = @booking.ends
              booking.start_km    = @booking.start_km
              booking.end_km      = @booking.end_km
              booking.status      = 0
              @tariff[:early]     = booking.get_fare
            end
          end
        end
      end
      render json: {html: render_to_string("/layouts/calculator/reschedule.haml", layout: false)}
    end
  end

	def careers
		@meta_title = "Zoomcar Careers | #{HOSTNAME}"
		@meta_description = "Zoomcar Careers"
		@meta_keywords = "zoomcar careers"
		@canonical = "http://#{HOSTNAME}/careers"
	end

	def city
		@meta_title = @city.meta_title('attractions')
		@meta_description = @city.meta_description('attractions')
		@meta_keywords = @city.meta_keywords('attractions')
		@canonical = @city.link('attractions')
	end

	def deals
		render "main/deals/#{params[:id]}"
	end

	def deals_of_the_day
		@meta_title = "Zoomcar Deals Zone"
		@meta_keywords = "zoomcar deals"
		@deal = Deal.where("offer_start < ? AND offer_end > ?", Time.now, Time.now)
		@location = Array.new
		@cargroup = Array.new
		@sold_out = Array.new
		@discount = Array.new
		@deal.each_with_index do |d, i|
			@location[i] = Location.where(id: d.location_id).first
			@cargroup[i] = Cargroup.where(id: d.cargroup_id).first
			@sold_out[i] = d.booking_id.present? || d.sold_out
			@discount[i] = d.discount
		end
		render "main/deals/offers"
	end

	def device
		render json: {html: ''}
	end

	def eligibility
		@meta_title = "Is Zoomcar For Me? Eligibility Policy | Zoomcar"
		@meta_description = "Read the eligibility policy from Zoomcar. Members must be #{CommonHelper::MIN_AGE} years with driving license and member should be able to pay by credit or debit card"
		@meta_keywords = "zoomcar eligibility policy"
		@canonical = "http://#{HOSTNAME}/eligibility"
		@header = 'policy'
	end

	def faq
		@meta_title = "Zoomcar Frequently Asked Questions (FAQs) | Zoomcar"
		@meta_description = "Read answers about Zoomcar to the most frequently asked questions on our FAQ page"
		@meta_keywords = "zoomcar faqs"
		@canonical = "http://#{HOSTNAME}/#{@city.link_name.downcase}/faq"
		@header = 'help'
		render "/main/pricing/#{@city.pricing_mode}/faq"
	end

	def fees
		@meta_title = "Zoomcar Fees Policy | Zoomcar"
		@meta_description = "Read Zoomcar fees policy for any returning vehicle late, returning vehicle to wrong location, traffic and parking violations, key not returned at end of reservation, accident & Zoomcar rule violations" 
    @meta_keywords = "zoomcar fees policy"
		@canonical = "http://#{HOSTNAME}/#{@city.link_name.downcase}/fees"
		@header = 'policy'
		render "/main/pricing/#{@city.pricing_mode}/policy"
	end

	def get_locations_map
		@city = City.find_by_id(params[:id]) if !params[:id].blank?
		@zoom = params[:zoom] if !params[:zoom].blank?
		render json: {html: render_to_string("locations_map", layout: false)}
	end

	def handover
		@meta_title = "Things to know before you Zoom off | #{HOSTNAME}"
		@meta_description = "Zoomcar Handover"
		@meta_keywords = "zoomcar handover"
		@canonical = "http://#{HOSTNAME}/handover"
		@header = 'help'
	end

	def holidays
		@meta_title = "List of Holidays | Zoomcar"
		@meta_description = "Zoom off on Holidays "
		@meta_keywords = "zoomcar holidays"
		@canonical = "http://#{HOSTNAME}/#{@city.link_name.downcase}/holidays"
	end

	def homepage
		@meta_title = "Self Drive Cars Rental In #{@city.name} | Join Online, Book A Car & Drive | Zoomcar"
		@meta_description = "Book a self-driven car online. Self driving car rental made easy like never before, simply join us for renting a car by the hour or day. Includes fuel, insurance & taxes"
		@meta_keywords = "zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
		@canonical = "http://#{HOSTNAME}/#{@city.link_name.downcase}"
		@header = 'homepage'
		@noindex = true
		#expires_in 1.months, :public => true, 'max-stale' => 0 #if Rails.env == 'production'
	end

	def howitworks
		@meta_title = "Self Drive Cars Rental In #{@city.name} | Join Online, Book A Car & Drive | Zoomcar"
		@meta_description = "Know how Zoomcar works"
		@meta_keywords = "how zoomcar works"
		@canonical = "http://#{HOSTNAME}/howitworks"
		@header = 'help'
	end

	def signup
		@meta_title = "Self Drive Cars Rental In #{@city.name} | Join Online, Book A Car & Drive | Zoomcar"
		@meta_description = "Signup for Zoomcar"
		@meta_keywords = "how zoomcar works"
		@canonical = "http://#{HOSTNAME}/signup"
	end

	def howtozoom
		@meta_title = "Self Drive Cars Rental In #{@city.name} | Join Online, Book A Car & Drive | Zoomcar"
		@meta_description = "Read how to be a better Zoomcar Member"
		@meta_keywords = "zoomcar member"
		@canonical = "http://#{HOSTNAME}/howtozoom"
		@header = 'help'
	end

	def index
		if !@cityp.blank?
			@meta_title = @city.meta_title
			@meta_description = @city.meta_description
			@meta_keywords = @city.meta_keywords
			@header = 'homepage'
			@canonical = @city.link
		else
			redirect_to @city.link and return if !session[:city].blank?
			@city = City.lookup('bangalore') if !@city.active
			@meta_title = City.meta_title
			@meta_description = City.meta_description
			@meta_keywords = City.meta_keywords
			@header = 'homepage'
			@canonical = City.link
		end
		render :inactive and return if @city.prelaunch
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
		@meta_title = "Zoomcar Member Agreement | Zoomcar"
		@meta_description = "Read Zoomcar Member agreement is a contract and governs the relationships, rights, and obligations between Zoomcar India Private Limited and the Member"
		@meta_keywords = "zoomcar Member agreemen"
		@canonical = "http://#{HOSTNAME}/member"
		@header = 'policy'
	end

	def offers
		@meta_title = "Zoom for Less in #{@city.name} | #{HOSTNAME}"
		@meta_description = "Offers running in #{@city.name} on Zoomcar"
		@meta_keywords = "zoomcar offers"
		@canonical = "http://#{HOSTNAME}/#{@city.link_name.downcase}/offers"
		@header = 'offers'
	end

	def outstation
		@meta_title = "Outstation Car Rental | Rent Self-Drive Car For Outstation Trips"
		@meta_description = "Zoomcar provides local car rental for outstation trips outside Karnataka and Maharashtra state.  Book outstation car for Goa, Kerala, Tamil Nadu and Andhra Pradesh at budget prices"
		@meta_keywords = "Outstation car rental, outstation car hire, self drive car for outstation"
		@canonical = "http://#{HOSTNAME}/outstation"
		@header = 'help'
	end

	def privacy
		@meta_title = "Zoomcar Privacy Policy | Zoomcar"
		@meta_description = "Read Zoomcar website usage privacy policy and terms and conditions"
		@meta_keywords = "zoomcar privacy policy"
		@canonical = "http://#{HOSTNAME}/privacy"
		@header = 'policy'
	end

	def redirect
		redirect_to '/', :status => 404 and return
	end

	def reva
		@meta_title = "Electric Car Rental | Rent Reva For Self-Drive In #{@city.name}"
		@meta_description = "Zoomcar now offers eco friendly electric car for hire in #{@city.name}. Now rent Mahindra Reva E20 India's only fully electric car by the hour or by the day."
		@meta_keywords = "electric car hire, hire Reva in #{@city.name}"
		@canonical = "http://#{HOSTNAME}/reva"
		@header = 'help'
	end

	def safety
		@meta_title = "Zoomcar Safety | Zoomcar"
		@meta_description = "Zoomcar guidelines for a safe zooming experience"
		@meta_keywords = "zoomcar, zoom, safety"
		@canonical = "http://#{HOSTNAME}/#{@city.link_name.downcase}/safety"
		@header = 'help'
	end

	def tariff
		@meta_title = "Zoomcar Rental Tariffs In #{@city.name} | Zoomcar"
		@meta_description = "Zoomcar offers the simplest, easiest car-rental tariff in #{@city.name}. Find out what all is included"
		@meta_keywords = "zoomcar hire tariffs"
		@canonical = "http://#{HOSTNAME}/#{@city.link_name}/tariff"
		@header = 'tariff'
		render "/main/pricing/#{@city.pricing_mode}/tariff"
	end

	def mobile_redirect
		@meta_title = "Zoomcar Rental Tariffs In #{@city.name} | Zoomcar"
		@meta_description = "Zoomcar offers the simplest, easiest car-rental tariff in #{@city.name}. Find out what all is included"
		@meta_keywords = "zoomcar hire tariffs"
		@canonical = "http://#{HOSTNAME}/mobile_redirect"
		@header = 'mobile_redirect'
		render '/main/mobile_redirect', layout: false
	end
end
