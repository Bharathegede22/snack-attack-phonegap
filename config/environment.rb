# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Web::Application.initialize!
config.action_mailer.default_url_options = { :host => 'localhost:3000' }
 

