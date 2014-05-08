require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'rack/cache'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Web
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
		config.time_zone = 'Kolkata'
		config.autoload_paths += %W(#{config.root}/lib)
		
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    
    # Exception Handling    
    config.middleware.use ExceptionNotification::Rack, 
    	:email => {
		    :email_prefix => "[Zoomcar Error] ", 
		    :sender_address => %{"Zoomcar Error" <error@zoomcar.in>},
		    :exception_recipients => %w{error@zoomcar.in}
		}
		
		config.to_prepare do
			Devise::Mailer.layout "email"
		end
		
		# Disabling Rack Caching
    config.middleware.delete Rack::Cache
    
  end
end
class Time
  def self.today
    Time.now.beginning_of_day 
  end
end
configurations = YAML.load(File.read(File.join(::Rails.root.to_s, 'config', 'configurations.yml')))
HOSTNAME = configurations['hostname']
