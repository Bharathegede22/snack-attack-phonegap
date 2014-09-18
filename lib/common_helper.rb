module CommonHelper
	
	# Fees
	SMOKING = 1000
	OVERSPEEDING = 500
	
	HIRE_TYPE = [['Full Time', 0],['Part Time',1],['Internship',2]]
	DEPARTMENT = [['Call Centre',0],['Marketing',1],['Technology',2],['Operations',3],['Analytics',4],['Others',5],['Product',6]]
	
	CAR_TYPE = [['Hatchback', 1], ['SUV', 2], ['Sedan', 3], ['Coupe2D', 4]]
  DRIVE = [['Front Wheel', 1], ['Rear Wheel Drive', 2]]
  FUEL = [['Diesel', 1], ['Electric', 2]]
  
  RATINGS_QUESTION = ["How was your booking experience?", 
  	"How was the car condition?", 
  	"How was the Pick-Up location?", 
  	"How was the fleet executive's behaviour?"
  ]
  RATINGS = [["Terrible", 1], ["Bad", 2], ["Average", 3], ["Good", 4], ["Excellent", 5]]
  
	CUSTOMER_CARE = "080-33013371"
	CUSTOMER_CARE_EMAIL = "contact@zoomcar.in"
	KLE_UNLOCK_NUMBER = ""
	INTERCEPTOR_NUMBER = "9703356074"
	LIABILITY           = '5,000'
	ALLOTMENT           = 90
	WEEKDAY_DISCOUNT    = 40
	BOOKING_WINDOW      = 60
	MIN_AGE             = 21
	
	JIT_DEPOSIT_CANCEL  = 24
	JIT_DEPOSIT_ALLOW   = 24
	JIT_DEPOSIT_ALERT   = 48

	SECURITY_DEPOSIT	= 5000
	
  BLACKLISTED_STATUS = 1
  BOOKING_WINDOW = 60
  
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
