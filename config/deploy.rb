require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
# require 'mina/rvm'    # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :domain, 'shop.demo.dev.yellowen.com'
set :deploy_to, '/home/demo/shop'
set :repository, 'git://github.com/lxsameer/Bazaar.git'
set :branch, 'master'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['log', 'public/assets']

# Optional settings:
#   set :user, 'foobar'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.
set :user, 'demo'

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .rbenv-version to your repository.
  invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[mkdir -p "#{deploy_to}/shared/public/assets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[mkdir -p "#{deploy_to}/current/tmp/pids/"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]

  queue! %[touch "#{deploy_to}/shared/config/database.yml"]
  queue  %[echo "-----> Be sure to edit 'shared/config/database.yml'."]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    queue %[rm #{deploy_to}/current/db/production.sqlite3]
    invoke :'rails:db_migrate'
    to :launch do
      queue %[bundle exec thin stop -C #{deploy_to}/current/config/thin.yml]
      invoce :'rake[db:seed]'
      invoce :'rake[spree_sample:load]'
      invoke :'rails:assets_precompile'
      queue %[bundle exec thin start -C #{deploy_to}/current/config/thin.yml]
    end
  end
end

desc 'production log'
task :plog do
  queue %[tail -n 100 #{deploy_to}/current/log/production.log]
end

desc 'thin log'
task :tlog do
  queue %[tail -n 100 #{deploy_to}/current/log/thin.3000.log]
end
