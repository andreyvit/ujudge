
require 'iconv'

class String
  def to_cp1251
    Iconv.conv('cp1251', 'utf-8', self)
  end
end

namespace :chetv do 
  namespace :users do
    desc "Exports users in chetvertakov's user list format, use AFTER=25 for id"
    task :export => :environment do
      after = (ENV['AFTER'] || 0).to_i
      f = File.open("users.sql", "w")
      Team.find(:all, :conditions => ['id > ?', after]).each do |user|
        ps = user.active_password_set
        puts "team #{user.id} does not have a password!!!!!" if ps.nil?
        next if ps.nil?
        data = {
          :userid => user.id,
          :login => "team#{user.id}",
          :password => "///" + ps.passwords.find(:all).collect {|p| p.text}.join('///') + "///",
          :name1 => user.display_name,
          :title => user.display_name,
          :selected_tourid => 500
        }
        f.puts %Q/INSERT INTO wso6_users (#{data.collect {|k,v| k.to_s}.join(',')}) VALUES (#{data.collect {|k,v| %Q!"#{v.to_s.to_cp1251}"!}.join(',')});/
      end
      f.close
    end

    desc "Exports users in space-delimited list format, use AFTER=25 for id"
    task :exp2 => :environment do
      after = (ENV['AFTER'] || 0).to_i
      f = File.open("users.txt", "w")
      Team.find(:all, :conditions => ['id > ?', after]).each do |user|
        p = user.password_sets.inject([]) {|a,s| a + s.passwords.find(:all) }.collect {|p| p.text}.join(' ')
        f.puts "#{user.email} #{p} #{user.name.gsub(' ', '_').to_cp1251}"
      end
      f.close
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