class Judge::Client::Client
  include DRb::DRbUndumped
  
  class CollectingReporter
    
    def initialize()
      @queue = []
      @queue.extend(MonitorMixin)
    end
    
    def extract
      r = nil
      @queue.synchronize do 
        r = @queue.collect { |c| c }
        @queue.clear
      end
      r
    end
    
    def prepend(events)
      @queue.synchronize do 
        @queue.unshift(*events)
      end
    end
    
    def method_missing(id, *args)
      @queue.synchronize do
        @queue << [id, *args]
      end
    end
    
  end
  
  class MultiplexingReporter
    
    def initialize
      @reps = []
    end
    
    def <<(rep)
      @reps << rep
    end
    
    def method_missing(meth, *args)
      @reps.each { |r| r.send(meth, *args) }
    end
    
  end
  
  attr_reader :name
  attr_reader :server
  
  def initialize(server)
    @server = server
    @tester = Tester.new
    @name = "client-at" #"-#{get_local_ip}"
    @state = :idle
    @monitor = []
    @monitor.extend(MonitorMixin)
    @job_changed = @monitor.new_cond
    @vfs = VirtualFileSystem.new(File.join(UJUDGE_ROOT, 'tmp', 'vfscache'), @server)
    
    x = Judge::Solution
    x = Judge::Problem
    x = Judge::Test
    x = Judge::Client::DiffChecker
    x = Judge::Client::NativeChecker
    x = Judge::Client::NativeExecutableCompiler

    # s = Marshal.load(File.open(File.join(UJUDGE_ROOT, 'test.dmp'), 'r') { |f| f.read })
    # puts "s.class = #{s.class.name}"
    
    @reporter = MultiplexingReporter.new
    @reporter << (@creporter = CollectingReporter.new)
    @reporter << Judge::LogReporter.new($stdout)
    
    @server.register_client(self)
    @thread = Thread.new do
      loop do
        sleep 2
        begin
          events = @creporter.extract
          
          begin
            solution = @server.ping(self, @state, events)
          rescue Exception => e
            puts "ping error, probably server is down: #{e}"
            puts e.backtrace
            @creporter.prepend(events) # put back
            next
          end
          
          if Symbol === solution
            case solution
            when :idle
            when :reregister
              @server.register_client(self)
            else
              puts "WARNING: ignoring unknown server reply '#{solution}'"
            end
            next
          end
          
          @monitor.synchronize do 
            if @state == :idle && !solution.nil?
              @solution = solution
              @state = :testing_starting
              puts "received a job from server: #{solution.unique_name(:global)}"
              @job_changed.signal
            end
          end
        rescue Exception => e
          puts "exception: #{e}"
          puts e.backtrace
        end
      end
    end
  end
  
  def ping
    t = Time.new
    puts "Ping #{t}"
    return t
  end
  
  def fetch_file(path)
    
  end
  
  
  def main_loop
    loop do
      sol = nil
      @monitor.synchronize do
        @job_changed.wait_while { @solution.nil? }
        @state = :testing
        sol = @solution
      end
      
      sol.problem.tests
      
      File.open('dump', 'w') do |f|
        f.write(YAML.dump(sol))
      end
      
      puts "loading data from server..."
      
      
      puts "testing..."
      @tester.compile_and_evaluate(@reporter, sol, @vfs)
      
      @monitor.synchronize do
        @solution = nil
        @state = :idle
        @job_changed.signal
      end
    end
  end

  def self.start_client(options)
    options.port ||= 15837
    options.host ||= 'localhost'
    uri = "druby://#{options.host}:#{options.port}"
    DRb.start_service("druby://localhost:9004", nil)
    begin
      server = DRbObject.new(nil, uri)
      puts "Connected to #{uri}."
      $root = self.new(server)
      $root.main_loop
      DRb.thread.join
    ensure
      puts "Stopping service."
      DRb.stop_service
    end
  end

  def self.connect_server(options = OpenStruct.new)
    options.port ||= 15837
    options.host ||= 'localhost'
    uri = "druby://#{options.host}:#{options.port}"
    DRb.start_service("druby://localhost:9004", nil)
    server = DRbObject.new(nil, uri)
    puts "Connected to #{uri}."
    $root = self.new(server)
    return server
  end

end
