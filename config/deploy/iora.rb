server 'newkochiku.icisapp.com', user: 'ops', roles: %w{web app db worker}
set :deploy_to, "/home/ops/kochiku-master"
set :rails_env, 'production'
set :repo_url, "git://github.com/IoraHealth/kochiku.git"
set :branch, 'square-master'
set :rvm_ruby_version, '2.3.0'

after  "deploy:publishing", "deploy:restart"
