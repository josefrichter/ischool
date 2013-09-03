set :application, "ischoolcz"
set :repository, "https://github.com/josefrichter/ischool.git"
set :scm, "git"

role :web, "server5.railshosting.cz"
role :app, "server5.railshosting.cz"
role :db,  "server5.railshosting.cz", :primary => true

set :deploy_to, "/home/ischoolcz/app/"
set :user, "ischoolcz"

set :use_sudo, false

task :after_update_code, :roles => [:app, :db] do
  run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
end


namespace :deploy do
  task :start, :roles => :app do
  end
end

namespace :deploy do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

namespace :tail do
  desc "Tail production.log"
  task :default do
    run "tail -n 500 /home/deployer/app/current/log/production.log"
  end
end