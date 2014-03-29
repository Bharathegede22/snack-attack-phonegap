module CommonHelper
	
	HIRE_TYPE = [['Full Time', 0],['Part Time',1],['Internship',2]]
	DEPARTMENT = [['Call Centre',0],['Marketing',1],['Technology',2],['Operations',3]]
	
	CAR_TYPE = [['Hatchback', 1], ['SUV', 2], ['Sedan', 3], ['Coupe2D', 4]]
  DRIVE = [['Front Wheel', 1], ['Rear Wheel Drive', 2]]
  FUEL = [['Diesel', 1], ['Electric', 2]]
  RATINGS = [["Terrible", 1], ["Bad", 2], ["Average", 3], ["Good", 4], ["Excellent", 5]]
  
	FUNFACTS = [
		"For every Zoom vehicle added to the road, we will take off 15-17 vehicles", 
		"Over the life of a Zoom vehicle, we will help save 150 tons of CO2 from entering Bangalore's air", 
		"The first car rental company was started in the United States in 1918", 
		"The first electric vehicle was actually introduced in New York City in 1897!", 
		"At 62 kms, the Outer Ring Rd is the longest road within Bangalore's city limits", 
		"There are over 20 1st Main Rds in Bangalore!", 
		"Bangalore has over 35 lakh vehicles", 
		"When completed, the Namma Metro will extend 114 kms and will have over 100 stations",
		"Zoom is the only rental service in India to offer a plug in electric vehicle for self-drive (Reva E2O)",
		"Zoom is the only rental service in India to offer a luxury vehicle to hire by the hour (BMW 320d)"
	]
	
	DISCOUNT_CODES = ['BUSINESS', 'MYSTERY']
	CUSTOMER_CARE = "080-67684475"
	CUSTOMER_CARE_EMAIL = "contact@zoomcar.in"
	LIABILITY = '5,000'
	ALLOTMENT = 90
	WEEKDAY_DISCOUNT = 40
	BOOKING_WINDOW = 60
	MIN_AGE = 21
	
	ENCODING_ARRAY = ["7", "c", "i", "j", "o", "k", "z", "l", "q", "r", "m", "8", "h", "u", "g", "w", "3", "1", "y", "p", "5", "s", "0", "d", "a", "e", "v", "t", "2", "4", "f", "b", "x", "6", "n", "9"]
  
  STATE = [
  	'Andaman and Nicobar Islands',
		'Andhra Pradesh',
		'Arunachal Pradesh',
		'Assam',
		'Bihar',
		'Chandigarh',
		'Chhattisgarh',
		'Dadra and Nagar Haveli',
		'Daman and Diu',
		'Delhi',
		'Goa',
		'Gujarat',
		'Haryana',
		'Himachal Pradesh',
		'Jammu and Kashmir',
		'Jharkhand',
		'Karnataka',
		'Kerala',
		'Lakshadweep',
		'Madhya Pradesh',
		'Maharashtra',
		'Manipur',
		'Meghalaya',
		'Mizoram',
		'Nagaland',
		'Odisha',
		'Puducherry',
		'Punjab',
		'Rajasthan',
		'Sikkim',
		'Tamil Nadu',
		'Tripura',
		'Uttar Pradesh',
		'Uttarakhand',
		'West Bengal'
	]
		
  class << self
  	def encode(c,id)
  		if Rails.env == 'production'
		    temp = case c.downcase
		    when 'attraction' then 10000000
		    when 'job' then 20000000
		    #when 'payment' then 30000000
		    when 'cargroup' then 40000000
		    when 'location' then 50000000
		    when 'booking' then 10000000000000
		    when 'payment' then 20000000000000
		    else 0
		    end
		  else
		  	temp = case c.downcase
		    when 'attraction' then 10000000
		    when 'job' then 20000000
		    when 'payment' then 30000000
		    when 'cargroup' then 40000000
		    when 'location' then 50000000
		    when 'booking' then 10000000000000
		    #when 'payment' then 20000000000000
		    else 0
		    end
		  end
      str = ''
			temp = 0 + temp + id
			while temp > 35
				i = temp/36
				str << ENCODING_ARRAY[temp - i*36]
				temp = temp/36
			end
			str << ENCODING_ARRAY[temp]
			return str.reverse
    end
		
		def escape(content)
      if content
        return content.downcase.gsub(/[^0-9a-z]/i,'-').gsub(/-+/,'-').chomp('-')
      else
        return nil
      end
    end
    
  	def decode(str)
  		return nil if str.empty?
		  id = 0
		  pos = 0
		  str.reverse.each_char do |s|
		    id = id + ENCODING_ARRAY.index(s)*(36**pos)
		    pos = pos + 1
		  end
		  if Rails.env == 'production'
				return ['payment',id-20000000000000] if id > 20000000000000
				return ['booking',id-10000000000000] if id > 10000000000000
				return ['location',id-50000000] if id > 50000000
				return ['cargroup',id-40000000] if id > 40000000
				#return ['payment',id-30000000] if id > 30000000
				return ['job',id-20000000] if id > 20000000
		    return ['attraction',id-10000000] if id > 10000000      
		    return ['',nil]
		  else
		  	#return ['payment',id-20000000000000] if id > 20000000000000
				return ['booking',id-10000000000000] if id > 10000000000000
				return ['location',id-50000000] if id > 50000000
				return ['cargroup',id-40000000] if id > 40000000
				return ['payment',id-30000000] if id > 30000000
				return ['job',id-20000000] if id > 20000000
		    return ['attraction',id-10000000] if id > 10000000      
		    return ['',nil]
		  end
    end
  end
  
end
