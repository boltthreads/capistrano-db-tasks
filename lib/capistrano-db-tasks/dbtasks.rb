require File.expand_path("#{File.dirname(__FILE__)}/util")
require File.expand_path("#{File.dirname(__FILE__)}/database")
require File.expand_path("#{File.dirname(__FILE__)}/asset")
require File.expand_path("#{File.dirname(__FILE__)}/compressors/base")
require File.expand_path("#{File.dirname(__FILE__)}/compressors/bzip2")
require File.expand_path("#{File.dirname(__FILE__)}/compressors/gzip")

set :local_rails_env, ENV['RAILS_ENV'] || 'development' unless fetch(:local_rails_env)
set :rails_env, fetch(:stage) || 'production' unless fetch(:rails_env)
set :db_local_clean, false unless fetch(:db_local_clean)
set :assets_dir, 'system' unless fetch(:assets_dir)
set :local_assets_dir, 'public' unless fetch(:local_assets_dir)
set :skip_data_sync_confirm, (ENV['SKIP_DATA_SYNC_CONFIRM'].to_s.downcase == 'true')
set :disallow_pushing, false unless fetch(:disallow_pushing)
set :compressor, :gzip unless fetch(:compressor)

namespace :capistrano_db_tasks do
  task :check_can_push do
    raise "pushing is disabled, set disallow_pushing to false to carry out this operation" if fetch(:disallow_pushing)
  end
end

namespace :db do
  namespace :local do
    desc 'Synchronize your local database using remote database data'
    task :sync do
      on roles(:db) do
        puts "Local database: #{Database::Local.new(self).database}"
        if fetch(:skip_data_sync_confirm) || Util.prompt('Are you sure you want to erase your local database with server database')
          Database.remote_to_local(self)
        end
      end
    end
  end

  desc 'Synchronize your local database using remote database data'
  task :pull => "db:local:sync"

  desc 'Synchronize your remote database using local database data'
  task :push => "db:remote:sync"
end

namespace :assets do
  namespace :local do
    desc 'Synchronize your local assets using remote assets'
    task :sync do
      on roles(:app) do
        puts "Assets directories: #{fetch(:local_assets_dir)}"
        if fetch(:skip_data_sync_confirm) || Util.prompt("Are you sure you want to erase your local assets with server assets")
          Asset.remote_to_local(self)
        end
      end
    end
  end

  desc 'Synchronize your local assets using remote assets'
  task :pull => "assets:local:sync"
end

namespace :app do
  namespace :local do
    desc 'Synchronize your local assets AND database using remote assets and database'
    task :sync do
      puts "Local database     : #{Database::Local.new(self).database}"
      puts "Assets directories : #{fetch(:local_assets_dir)}"
      if fetch(:skip_data_sync_confirm) || Util.prompt("Are you sure you want to erase your local database AND your local assets with server database and assets(#{fetch(:assets_dir)})")
        on roles(:db) do
          Database.remote_to_local(self)
        end

        on roles(:app) do
          Asset.remote_to_local(self)
        end
      end
    end
  end

  desc 'Synchronize your local assets AND database using remote assets and database'
  task :pull => "app:local:sync"
end
