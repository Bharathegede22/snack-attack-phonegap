set :stages, %w(production staging)
set :default_stage, "staging"
require 'capistrano/ext/multistage'

set :application, "web"
set :keep_releases, 5

ssh_options[:user] = "root"
ssh_options[:keys] = "/root/.ssh/id_rsa"
ssh_options[:port] = 2255

set :scm, :git
set :repository, "ssh://ourserver/#{application}.git"
set :deploy_to, "/var/www/#{application}"
set :deploy_via, :remote_cache
set :rails_env, 'production'

