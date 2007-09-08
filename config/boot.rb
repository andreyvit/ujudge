# Don't change this file. Configuration is done in config/environment.rb and config/environments/*.rb

unless defined?(RAILS_ROOT)
  root_path = File.join(File.dirname(__FILE__), '..')
  unless RUBY_PLATFORM =~ /mswin32/
    require 'pathname'
    root_path = Pathname.new(root_path).cleanpath(true).to_s
  end
  RAILS_ROOT = root_path
end

if File.directory?("#{RAILS_ROOT}/vendor/rails")
  require "#{RAILS_ROOT}/vendor/rails/railties/lib/initializer"
else
  require 'rubygems'
  require 'initializer'
end

Rails::Initializer.run(:set_load_path)

# customization (in boot.rb because needed by something that does not require environment.rb)
unless defined?(UJUDGE_ROOT)
  prevdir = Dir.pwd
  Dir.chdir(RAILS_ROOT)
  UJUDGE_ROOT = Dir.pwd # unlike RAILS_ROOT, this is always an absolute path
  Dir.chdir(prevdir) unless UJUDGE_ROOT == prevdir
end
