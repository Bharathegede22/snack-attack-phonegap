module BookingsHelper

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
      flash[:error] = "Something went wrong please try after some time"
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
      flash[:error] = "Something went wrong please try after some time"
      [nil,nil]
    end
    
  end
  
end
