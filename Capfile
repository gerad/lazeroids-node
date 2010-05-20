load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

default_run_options[:pty] = true

set :application, "lazeroids-node"
set :repository,  "git://github.com/gerad/lazeroids-node.git"
set :scm, :git

set :user, "app"

role :app, "lazeroids.com"

namespace :deploy do
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} restart lazeroids"
  end
end
