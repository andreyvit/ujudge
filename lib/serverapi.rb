
x = Judge::Test

module Server
  
  def self.connect
    @@localserver = DRb.start_service('druby://localhost:0')
    @@server = DRbObject.new(nil, "druby://#{GlobalConfig.instance.server_url}")
  end
  
  def self.instance
    @@server
  end
  
  def self.status
    @@server.get_status
  rescue
    RAILS_DEFAULT_LOGGER.warn "Cannot connect to server, error #{$!}"
    {:status => :cannot_connect}
  end
  
  def self.ok?
    self.status[:status] == :ok
  end
  
  def self.start_processing_tests_upload(upload_id)
    @@server.start_processing_tests_upload(upload_id)
  end
  
  def self.clients_count
    @@server.clients_count
  #rescue
  #  0
  end
  
  def self.get_tests_count(problem_id)
    @@server.get_tests_count(problem_id)
  end
  
  def self.get_tests(problem_id)
    @@server.get_tests(problem_id)
  end
  
  def self.get_rating(contest_id, team_id)
    @@server.get_rating(contest_id, team_id)
  end
  
  def self.submit(*args)
    @@server.submit(*args)
  end
  
  def self.get_submittion_text(*args)
    @@server.get_submittion_text(*args)
  end
  
  def self.queue_size
    @@server.queue_size
  rescue
    Run.count(:conditions => 'state = 0 or state = 1')
  end
  
end
