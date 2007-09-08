require 'railmail/action_mailer'

ActionMailer::Base.class_eval do
  include Railmail::ActionMailer::InstanceMethods
end

module Railmail
  def self.init(config, directory)
    config.controller_paths << File.join(directory, 'app', 'controllers')
    $LOAD_PATH << File.join(directory, 'app', 'controllers')
    $LOAD_PATH << File.join(directory, 'app', 'models')
    $LOAD_PATH << File.join(directory, 'app', 'helpers')
    
  end
end

