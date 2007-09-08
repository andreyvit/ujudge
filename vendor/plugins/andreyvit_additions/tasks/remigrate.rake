
namespace :db do
  desc "Migrate one version back (or to the version specified as OLD=x), and then up to the current"
  task :remigrate => :environment do
    current_version = ActiveRecord::Migrator.current_version
    old_version = (ENV["OLD"] ? ENV["OLD"].to_i : current_version - 1)
    ActiveRecord::Migrator.migrate("db/migrate/", old_version)
    ActiveRecord::Migrator.migrate("db/migrate/", current_version)
    Rake::Task[:db_schema_dump].invoke if ActiveRecord::Base.schema_format == :ruby
  end
end
