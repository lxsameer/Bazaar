require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'
require "mina/rsync"

set :domain, 'shop.demo.dev.yellowen.com'
set :deploy_to, '/home/demo/shop'
set :repository, 'git://github.com/lxsameer/Bazaar.git'
set :branch, 'master'

set :rsync_options, %w[--recursive --delete --delete-excluded --exclude .git*]
# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['log']

# Optional settings:
set :user, 'demo'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.
set :term_mode, :system
set :forward_agent, true

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
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]
end

task :precompile do
  Dir.chdir settings.rsync_stage do
    system "cp -rv ../../public/assets/ ./public/"
  end
end

task "rsync:stage" do
  invoke "precompile"
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    invoke "rsync:deploy"
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    queue %[echo "-----------------------------"]
    queue %[echo "$HOME"]
    invoke :'rails:db_migrate'
    queue 'cd #{deploy_to}/current && bundle exec rake db:seed'
    queue "cd #{deploy_to}/current && bundle exec rake spree_sample:load"
    #invoke :'assets_precompile'
    to :launch do
      queue "touch #{deploy_to}/tmp/restart.txt"
      queue '#{deploy_to}/current/config/unicorn_init.sh restart'
    end
  end
end

desc 'Tail the unicorn log'
task :unilog => :environment do
  deploy do
    queue 'tail -n 100 #{deploy_to}/current/logs/unicorn.log'
  end
end
