
x = Judge::Test

module Server
  
  def self.connect
    @@localserver = DRb.start_service('druby://localhost:0')
    @@server = DRbObject.new(nil, 'druby://localhost:15837')
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
  
  def self.queue_size
    @@server.queue_size
  rescue
    Run.count(:conditions => 'state = 0 or state = 1')
  end
  
end
