source 'https://rubygems.org'
gem 'rails', '4.0.0'
gem 'mysql2'
gem 'devise'
#gem 'devise-async'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'
gem 'jquery-rails'
gem 'turbolinks'
gem 'jbuilder', '~> 1.2'
gem 'unicorn'
gem 'rvm-capistrano'
gem "exception_notification"
gem 'haml-rails'
gem "rfc822"
gem "paperclip"
gem 'rack-cache'
gem 'lacquer'
gem 'dalli'
gem 'sidekiq'
gem 'sinatra', '>= 1.3.0', :require => nil
gem 'fql'
gem 'countries'
gem 'aws-sdk'
gem "rest_client"
gem 'sprockets-image_compressor'
gem 'paper_trail', '~> 3.0.1'
gem 'geoip'
gem "browser"

group :development do
	gem 'capistrano'
end

group :production do
	gem 'newrelic_rpm'
end

group :assets do
	gem 'sass-rails', '~> 4.0.0'
	gem 'uglifier', '>= 1.3.0'
	gem 'coffee-rails', '~> 4.0.0'
	gem 'therubyracer', platforms: :ruby
	gem 'yui-compressor'
end

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

group :development, :test do
	gem 'debugger'
  gem "rspec"
  gem 'rspec-rails'
  gem 'rb-readline'
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'guard-cucumber'
  gem "factory_girl", "~> 4.4.0"
  gem "factory_girl_rails", "~> 4.4.0"
  gem "shoulda-matchers"  
  gem 'timecop'
  gem 'simplecov', :require => false
  gem 'simplecov-rcov', :require => false
  gem 'rake'
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  gem 'coveralls', :require => false  
end
