class AbtestController < ApplicationController
	
	def homepage
		@meta_title = "Self Drive Cars Rental In Bangalore | Join Online, Book A Car & Drive | Zoomcar.in"
		@meta_description = "Book a self-driven car online. Self driving car rental made easy like never before, simply join us for renting a car by the hour or day. Includes fuel, insurance & taxes"
		@meta_keywords = "zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
		@canonical = "http://#{HOSTNAME}"
		@header = 'homepage'
		@noindex = true
	end
	
	def homepagealt
		@meta_title = "Self Drive Cars Rental In Bangalore | Join Online, Book A Car & Drive | Zoomcar.in"
		@meta_description = "Book a self-driven car online. Self driving car rental made easy like never before, simply join us for renting a car by the hour or day. Includes fuel, insurance & taxes"
		@meta_keywords = "zoomcar, self drive car, self drive car rental, renting a car, self drive cars"
		@canonical = "http://#{HOSTNAME}"
		@header = 'homepage'
		@noindex = true
		render :homepage
	end
	
end
