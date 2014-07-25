require "rvm/capistrano"
require 'bundler/capistrano'
load 'deploy/assets'

set :rvm_ruby_string, '2.0.0@zoomweb'
set :rvm_type, :system

set :keep_releases, 5
set :domain_name, "test.zoomcartest.com"

default_run_options[:pty] = true
set :scm, :git
set :repository, "git@github.com:ZoomCar/web.git"
set :branch, "master"
set :deploy_via, :remote_cache
ssh_options[:forward_agent] = true

set :use_sudo, false
set :deploy_to, "/var/www/#{application}"
set :rails_env, "production"

role :web, "23.98.75.20"
role :app, "23.98.75.20"
role :db,  "23.98.75.20", :primary => true

ssh_options[:user] = "wheels"
ssh_options[:keys] = "~/.ssh/azure/test/private.key"
ssh_options[:port] = 2255

set :bundle_gemfile, "Gemfile"
set :bundle_dir, File.join(fetch(:shared_path), 'bundle')

namespace :deploy do	
	desc "Start Application"
  task :start, :roles => [:app] do
  end

	desc "Stop Application"
  task :stop, :roles => [:app] do
  end

  desc "Restart Application"
  task :restart, :roles => [:app] do
  end  
end

namespace :generic do	
	desc "Link up config files."
	task :configs, :roles => [:app] do
	  run "ln -s #{shared_path}/configurations.yml #{release_path}/config/configurations.yml"
	  run "ln -s #{shared_path}/database.yml #{release_path}/config/database.yml"
	  run "ln -s #{shared_path}/database.yml #{release_path}/config/varnishd.yml"
	  run "ln -s #{shared_path}/GeoLiteCity.dat #{release_path}/GeoLiteCity.dat"
	  run "rm #{release_path}/public/robots.txt"
	  run "ln -s #{shared_path}/robots.txt #{release_path}/public/robots.txt"
	  run "chmod 777 #{release_path}/public/sitemap.xml"
	end
	
	desc "Zero-downtime restart of Unicorn"
  task :unicorn_restart, :roles => :app do
    run "sudo /etc/init.d/unicorn restart_web"
  end

  desc "Start unicorn"
  task :unicorn_start, :roles => :app do
    run "sudo /etc/init.d/unicorn start_web"
  end

  desc "Stop unicorn"
  task :unicorn_stop, :roles => :app do
    run "sudo /etc/init.d/unicorn stop_web"
  end
  
  desc "Removing Varnish Cache"
  task :clear_cache, :roles => :app do
    run "cd #{release_path} ; bundle exec rails runner -e production \"Lacquer::Varnish.new.purge('.*')\""
  end
end
before "deploy:assets:precompile", "generic:configs"
after "deploy", "generic:unicorn_restart"
after "deploy", "deploy:cleanup"
after "deploy", "generic:clear_cache"
