class AbtestController < ApplicationController
	
	def homepage
		@meta_title = "Self Drive Cars Rental In Bangalore | Join Online, Book A Car & Drive | Zoomcar.in"
		@meta_description = "Book a self-driven car online. Self driving car rental made easy like never before, simply join us for renting a car by the hour or day. Includes fuel, insurance & taxes"
		@meta_keywords = "zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
		@canonical = "http://www.zoomcar.in"
		@header = 'homepage'
		@noindex = true
		#expires_in 1.months, :public => true, 'max-stale' => 0 #if Rails.env == 'production'
	end
	
end
