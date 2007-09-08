
namespace :db do 
  namespace :fixtures do
    desc "Dump fixtures from the current environment's database. Specify fixtures using FIXTURES=x,y"
    task :dump => :environment do
      if ENV['FIXTURES'].blank?
        raise "No FIXTURES value given. Set FIXTURES=x,y"
      else
      	ENV['FIXTURES'].split(',').collect {|s| s.strip}.each do |s|
      	  s = s.singularize if ActiveRecord::Base.pluralize_table_names
      	  s = s.camelize
	      eval(s).dump_to_fixture()
	    end
      end
    end
  end
  
  namespace :data do
    desc "Dump database data into files in db/data/*.yml. Use TABLE=ModelName"
    task :dump => :environment do
      unless File.directory?(File.expand_path("db/data", RAILS_ROOT))
        raise "Create db/data directory before using db:data:dump"
      end
      files = Dir[File.expand_path("db/data/**/*.yml", RAILS_ROOT)]
      files.each do |file|
        table_name = File.basename(file, '.yml')
        table_name = table_name.singularize if ActiveRecord::Base.pluralize_table_names
        model_name = table_name.camelize
        eval(model_name).dump_to_fixture(file)
      end
    end

    desc "Load database data from files in db/data/*.yml. Use TABLE=ModelName"
    task :load => :environment do
      unless File.directory?(File.expand_path("db/data", RAILS_ROOT))
        raise "Create db/data directory before using db:data:load"
      end
      files = Dir[File.expand_path("db/data/**/*.yml", RAILS_ROOT)]
      files.each do |file|
        table_name = File.basename(file, '.yml')
        table_name = table_name.singularize if ActiveRecord::Base.pluralize_table_names
        model_name = table_name.camelize
        eval(model_name).load_from_fixture(file)
      end
#      path = ENV['FILE']
#      if ENV['TABLE'].blank?
#        raise "No TABLE value given. Set TABLE=ModelName"
#      else
#        eval "#{ENV['TABLE']}.load_from_fixturex(path)"
#      end
    end
  end
end