require "rvm/capistrano"
require 'bundler/capistrano'
load 'deploy/assets'

set :rvm_ruby_string, '2.0.0@zoomweb'
set :rvm_type, :user

set :keep_releases, 5
set :domain_name, "www.zoomcartest.com"

default_run_options[:pty] = true
set :scm, :git
set :repository, "git@github.com:ZoomCar/web.git"
set :branch, "staging"
set :deploy_via, :remote_cache
ssh_options[:forward_agent] = true

set :use_sudo, false
set :deploy_to, "/var/www/#{application}"
set :rails_env, "staging"

role :web, "23.98.66.94"
role :app, "23.98.66.94"
role :db,  "23.98.66.94", :primary => true

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
    run "ln -s #{shared_path}/GeoLiteCity.dat #{release_path}/GeoLiteCity.dat"
    run "rm #{release_path}/public/robots.txt"
    run "ln -s #{shared_path}/robots.txt #{release_path}/public/robots.txt"
    run "chmod 777 #{release_path}/public/sitemap.xml"
  end
  
  desc "Zero-downtime restart of Unicorn"
  task :unicorn_restart, :roles => :app do
    run "sudo /etc/init.d/unicorn restart"
  end

  desc "Start unicorn"
  task :unicorn_start, :roles => :app do
    run "sudo /etc/init.d/unicorn start"
  end

  desc "Stop unicorn"
  task :unicorn_stop, :roles => :app do
    run "sudo /etc/init.d/unicorn stop"
  end
  
  desc "Removing Varnish Cache"
  task :clear_cache, :roles => :app do
    run "cd #{release_path} ; bundle exec rails runner -e staging \"Lacquer::Varnish.new.purge('.*')\""
  end
end
before "deploy:assets:precompile", "generic:configs"
after "deploy", "generic:unicorn_restart"
after "deploy", "deploy:cleanup"
after "deploy", "generic:clear_cache"
after "deploy", "generic:update_cron"