require 'mina/git'
require 'mina/deploy'

require 'dotenv'
Dotenv.load

server = ENV['server'] || 'staging'
ip = ENV['STAGE_DOMAIN']

if server == 'production'
  ip = ENV['PROD_IP']
  branch_name = ENV['branch'] || 'production'
  set :deploy_to, #{deploy_path_for_production_react_app}
elsif server == 'uat'
  branch_name = ENV['branch'] || 'uat'
  set :deploy_to, #{deploy_path_for_uat_react_app}
else
  branch_name = ENV['branch'] || 'staging'
  set :deploy_to, #{deploy_path_for_staging_react_app}
end

set :repository, #{ssh_link_of_git_repo}
set :domain, ip
set :branch, branch_name
set :forward_agent, true
set :user, 'ubuntu'
set :keep_releases, '2'

set :shared_files, fetch(:shared_files, []).push('.env.local')

task :setup => :remote_environment do
  command %[touch "#{fetch(:shared_path)}/.env.local"]

  # Install nodejs
  command %(
    if ! which nodejs > /dev/null
      then
        echo "Installing nodejs 10"
        curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
        sudo apt -y install nodejs
      else
        echo "Nodejs is already installed."
    fi
  )

  # Install npm
  command %(
    if ! which npm > /dev/null
      then
        echo "Installing npm"
        sudo apt update && sudo apt install npm
      else
        echo "npm is already installed."
    fi
  )
end

desc "Deploys the current version to the server."
task :deploy => :remote_environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    command %{npm install}
    command %{npm run build}
    # node_modules not needed for the
    command %{rm -rf node_modules/}
    invoke :'deploy:cleanup'

    on :launch do
      in_path(fetch(:current_path)) do

      end
    end
  end
end
