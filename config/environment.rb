# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with rake gem:install on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make ActiveRecord store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run `rake -D time` for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_foo_session',
    :secret      => 'c9597495b554c3170739fa061c467e56602c06200e34da06b61a295179f5ebecf5cccc2a0cf3f389b19ce6cb61114cbdb1b59b923e78eb43790e95523f8b8e0f'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below
require 'ostruct'
require 'set'
require 'ftools'

require 'cached_model'
require 'memcache'
require 'memcache_util'

require 'russian_numerics'
require 'sql_random_row'
require 'international'
require 'translit'
require 'string_gen'
require 'serverapi'
require 'file_utils'
require 'pathname'

CACHE = MemCache.new 'localhost:11211', :namespace => 'ujudge'

Server.connect

if ENV['PREFIX']
  BASE_URL = ENV['PREFIX']
end

if Object.const_defined?('BASE_URL')
  module ActionController
    ActionController::Base.asset_host = BASE_URL
    class UrlRewriter
      alias old_rewrite_url rewrite_url
  
      # Prepends the BASE_URL to all of the URL requests created by the
      # URL rewriter in Rails.
      def rewrite_url(path, options)
        url = old_rewrite_url(path, options)
        url = url.gsub(@request.protocol + @request.host_with_port, '')
        url = BASE_URL + url
        url
      end
    end
  end
end
