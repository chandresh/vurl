require 'eycap/recipes'

default_run_options[:pty] = true
set :application, "vurl"
set :repository,  "git@github.com:veezus/vurl.git"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"
set :deploy_via, :remote_cache
set :group_writable, false

task :production do
  set :deploy_to, "/var/www/apps/#{application}"
  set :rails_env, 'production'
  set :branch, 'production'
end

task :staging do
  set :deploy_to, "/var/www/apps/#{application}-staging"
  set :rails_env, 'staging'
  set :branch, 'staging'
end

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion
set :scm, :git

role :app, "li44-246.members.linode.com"
role :web, "li44-246.members.linode.com"
role :db,  "li44-246.members.linode.com", :primary => true

set :user, "veez"
set :scm_username, "veez"
set :use_sudo, true


after "deploy:update_code", "create_symlinks"
after "deploy:update_code", "bundle_install"
after "deploy:restart", "resque:restart"

task :create_symlinks, :roles => :app, :except => {:no_release => true, :no_symlink => true} do
  run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  run "ln -nfs #{shared_path}/config/settings.yml #{release_path}/config/settings.yml"
  run "ln -nfs #{shared_path}/screenshots #{release_path}/public/screenshots"
end

task :bundle_install, :roles => :app do
  run "cd #{release_path} && bundle install --relock"
end


namespace :resque do
  task :restart, :roles => :app do
    run "sudo god restart resque-#{rails_env.downcase}"
  end
end

namespace :redis do
  task :restart, :roles => :app do
    run "sudo monit restart -g redis"
  end
end

namespace :deploy do
  desc "Phusion Passenger restart"
  task :restart do
    run "touch #{deploy_to}/current/tmp/restart.txt"
  end
end
