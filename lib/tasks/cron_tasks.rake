namespace :cron_tasks do
  desc "GeoCity"
  task :geocity do
    `cd /var/www/web/shared`
    `wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz .`
    `gzip -df  GeoLiteCity.dat.gz`
    `chmod 777 GeoLiteCity.dat`
  end
end