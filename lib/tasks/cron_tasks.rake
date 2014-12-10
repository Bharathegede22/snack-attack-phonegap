namespace :cron_tasks do
  desc "GeoCity"
  task :geocity do
    `cd /var/www/web/shared`
    `wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz .`
    `gzip -df  GeoLiteCity.dat.gz`
    `chmod 777 GeoLiteCity.dat`
  end

  # frequency : 2 min
  desc "Check if payment for deal booking is done"
  task :check_deal_booking_status do
  	database = YAML.load(File.read(File.join(::Rails.root.to_s, 'config', 'database.yml')))
  	require "common_helper"
  	env = Rails.env
  	connection = ActiveRecord::Base.establish_connection(
  		:adapter => database[env]["adapter"],
			:database => database[env]["database"],
			:username => database[env]["username"],
			:password => database[env]["password"],
			:host => database[env]["host"],
			:port => database[env]["port"]
  	)
    sql = "UPDATE deals SET booking_id = NULL, logged_at = NULL WHERE booking_id IS NOT NULL AND sold_out = 0 AND logged_at < '#{(Time.now.utc - 10.minutes).to_s(:db)}'"
    p sql
    ActiveRecord::Base.connection.execute(sql)
	end
end
