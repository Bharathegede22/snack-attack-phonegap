set :stages, %w(production staging az_staging)
set :default_stage, "staging"
require 'capistrano/ext/multistage'

set :application, "web"
set :keep_releases, 5

set :scm, :git
set :repository, "ssh://ourserver/#{application}.git"
set :deploy_to, "/var/www/#{application}"
set :deploy_via, :remote_cache