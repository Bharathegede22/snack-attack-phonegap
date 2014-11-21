module BookingsHelper
  include ApplicationHelper

  def admin_hostname
   ADMIN_HOSTNAME 
  end

  def admin_api_version
    ADMIN_API_VERSION
  end


  def get_inventory_from_json json_data
    begin
      json_result = JSON.parse(json_data)
      cars = json_result["cars"]
      results = Hash.new
      cars.each do |car|
        results[car["id"].to_s] = car["locations_availibility"]
      end
      [results,cars]
    rescue Exception => ex      
      Rails.logger.info "JsonParsingError: Error parsing response from search results from api===== #{ex.message}--- BookingsHelper"
      flash[:error] = "Sorry, our system is busy right now. Please try after some time."
      [nil,nil]
    end
  end

  def get_timeline_inventory_from_json timeline_from_admin
    begin
      json = JSON.parse(timeline_from_admin)  rescue nil
      result = json["inventory"]
      inventory = []
      result.each do |i|
        inventory << Inventory.new(i)
      end
      result = json["cargroup"]
      cargroup = Cargroup.new(result)
      result = json["location"]
      location = Location.new(result)
      [inventory,cargroup,location]  
    rescue Exception => e
      Rails.logger.info "JsonParsingError: Error parsing response from search results from api===== #{e.message}--- BookingsHelper"
      flash[:error] = "Sorry, our system is busy right now. Please try after some time."
      [nil,nil]
    end
    
  end

  def updated_params(params)  
    params[:city] = @city.name
    params[:auth_token] = @current_user.authentication_token
    params[:starts] = Time.zone.parse(session[:book][:starts]) if !session[:book].blank? && !session[:book][:starts].blank?
    params[:ends] = Time.zone.parse(session[:book][:ends]) if !session[:book].blank? && !session[:book][:ends].blank?
    params[:location_id] = session[:book][:loc] if !session[:book].blank? && !session[:book][:loc].blank?     
    params[:cargroup_id] = session[:book][:car] if !session[:book].blank? && !session[:book][:car].blank?
    params[:ref_initial] = session[:ref_initial] if !session[:ref_initial].blank?
    params[:ref_immediate] = session[:ref_immediate] if !session[:ref_immediate].blank?

    if session[:credits_applied] || params[:apply_credits].to_i == 1
      params[:credits_applied] = 1
      params[:credits_applied] = 0 if params[:remove_credits].to_i == 1
      params[:credits_applied] = 1 if params[:apply_credits].to_i == 1
    end

    params[:platform] = "web"
    return params
  end

  def update_sessions(args)
    promo = args["promo"]
    credits = args['credits']

    session[:promo_message] = promo["message"] if promo.present? && promo["message"].present?
    session[:promo_valid] = promo.present? && promo["valid"]
    if promo.present? && promo["code"].present? && promo["valid"] == true
      session[:promo_code] = promo["code"] if promo["code"].present?
      session[:promo_discount] = promo["discount"] if promo["discount"].present?
      session[:promo_offer_id] = promo["offer_id"] if promo["offer_id"].present?
      session[:promo_coupon_id] = promo["coupon_id"] if promo["coupon_id"].present?
    end

    if credits.present?
      session[:credits_applied] = credits["is_credit_applied"].to_i == 1
      session[:credits] = session[:credits_applied] ? credits["applied"] : nil
    end
  end

  def update_reschedule_params(params, booking)
    params[:promo] = booking.promo
    params[:city_id] = @city.id
    params[:auth_token] = @current_user.authentication_token
    params[:starts] = Time.zone.parse(params[:starts]) if params[:starts].present?
    params[:ends] = Time.zone.parse(params[:ends]) if params[:ends].present?
    params[:location_id] = @booking.location_id if @booking.location_id.present?      
    params[:cargroup_id] = @booking.cargroup_id if @booking.cargroup_id.present?
    params[:ref_initial] = session[:ref_initial] if !session[:ref_initial].blank?
    params[:ref_immediate] = session[:ref_immediate] if !session[:ref_immediate].blank?
    params[:platform] = "web"
    return params 
  end

  def make_promo_api_call(promo_details)
    url = "#{ADMIN_HOSTNAME}/mobile/v3/bookings/promo"
    res = admin_api_get_call(url, promo_details)
    begin
      res = JSON.parse(res)
      res
    rescue Exception => ex
      Rails.logger.info "JsonParsingError: Error parsing response from search results from api===== #{ex.message}--- BookingsHelper"
      flash[:error] = "Sorry, our system is busy right now. Please try after some time."
      {}
    end
  end

  def create_reschedule_offer(booking_id, promo, offer_discount)
    c = Charge.new
    c.booking_id = booking_id
    if promo["valid"] == true
      if promo["discount"] < offer_discount
        c.activity = "reschedule_discount"
        c.amount = offer_discount - promo["discount"]
        c.refund = 0
      elsif promo["discount"] > offer_discount
        c.activity = "reschedule_discount"
        c.amount = promo["discount"] - offer_discount
        c.refund = 2
      end
    else
      c.activity = "reschedule_discount"
      c.amount = offer_discount
      c.refund = 0
    end
    c.save!
  end

end
