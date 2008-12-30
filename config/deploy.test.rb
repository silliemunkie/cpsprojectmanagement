default_run_options[:pty] = true

set :repository,  "git@github.com:silliemunkie/cpsprojectmanagement.git"
set :scm, "git"
set :branch, "master"
set :deploy_via, :remote_cache

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

set :application, "CPS Project Management"
set :deploy_to, "/var/www/apps/#{application}"
set :user, "deploy"
set :admin_runner, "deploy"

role :app, "thecatatemysourcecode.com"
role :web, "thecatatemysourcecode.com"
role :db,  "thecatatemysourcecode.com", :primary => true
