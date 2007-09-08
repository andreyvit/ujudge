
require 'drb'
require 'socket'
require 'monitor'
require 'timeout'
#require 'zip/zip'
require 'tester/local'

def get_local_ip
  IPSocket.getaddress(Socket.gethostname)
end

class ClientProxy
  attr_accessor :run, :state
  
  EXPIRATION = 5 # seconds
  
  def initialize(server, client)
    @server = server
    @client = client
    @log = $stdout
    reset!
  end
  
  def reset!
    @state = :idle
    pinged
  end
  
  def idle?
    @state == :idle && @run.nil?
  end
  
  def alive?
    (Time.now - @last_ping) < EXPIRATION
  end
  
  def pinged
    @last_ping = Time.now
  end
  
  def process_events(events)
    events.each do |event|
      meth = event.shift
      # puts "#{meth}(#{event.collect {|x| x.to_s}.join(', ')})"
      self.send(:"process_#{meth}", *event)
    end
  end
  
  def banner(message)
    puts "=" * 80
    puts "      <<< #{message} >>>"
    puts "Run ID:   #{run.id}"
    puts "Team:     #{run.team.id} - #{run.team.name}"
    puts "Problem:  #{run.problem.display_name}"
    puts "Compiler: #{run.compiler.display_name}"
    puts "=" * 80
  end
  
  def process_start(solution)
    @log.puts "start processing of #{solution.unique_name(:global)}"
    run.state = 2 # testing
    run.state_assigned_at = Time.now
    @server.clients.synchronize do
      run.save!
      RunTest.delete_all(['run_id = ?', run.id])
    end
    banner "STARTING RUN EVALUATION"
  end
  
  def process_compiling
    return if @run.nil?
    @log.puts "compiling"
  end
  
  def process_compilation_error(output)
    return if @run.nil?
    @log.puts "compilation error, compiler output is:"
    @log.puts output
    run.state = 3
    run.state_assigned_at = Time.now
    run.outcome = 'compilation-error'
    run.details = output
    @server.clients.synchronize do
      run.save!
    end
    all_done
  end
  
  def process_testing(test)
    return if @run.nil?
    @log.puts "testing on test #{test.unique_name(:solution)}"
    @test = RunTest.new(:run => @run)
    @test.test_ord = test.ord
    @test.run_at = Time.now
  end
  
  def process_invokation_error(reason)
    return if @test.nil?
    @log.puts "invokation error: #{reason}"
    @test.outcome = reason.to_s
    @server.clients.synchronize do
      @test.save!
    end
  end
  
  def process_invokation_finished(stats)
    return if @test.nil?
    @log.puts "invokation finished."
  end
  
  def process_checking
    return if @test.nil?
    @log.puts "checking"
  end
  
  def process_checking_problem(reason)
    return if @test.nil?
    @log.puts "checker problem: #{reason}."
    @test.outcome = "checker-problem-#{reason}"
    @server.clients.synchronize do
      @test.save!
    end
  end
  
  def process_checking_finished(result, stats)
    return if @test.nil?
    @log.puts "checking done: #{result}."
    @test.outcome = result.to_s
    @test.partial_answer = stats.partial_answer unless stats.partial_answer.nil?
    @server.clients.synchronize do
      @test.save!
    end
  end

  def process_finished
    return if @run.nil?
    @log.puts "finished."
    run.state = 3
    run.state_assigned_at = Time.now
    run.outcome = 'tested'
    # run.details = nil
    @server.clients.synchronize do
      run.save!
    end
    @server.add_job(SetPointsJob.new(@server, run)) 
    banner "DONE TESTING"
    all_done
  end
  
  def all_done
    ActualResults::CalculatedRating.invalidate(@run.team.contest)
    @run = nil # hurra, done!
  end
end

class Job
end

class SetPointsJob < Job
  def initialize(server, run)
    @server = server
    @run    = run
  end
  
  def run
    # calculate points for this run in points mode
    # TODO: calculate run state in ACM mode
    @server.clients.synchronize do
      @sol = Judge::Solution.new(@run)
      @problem = @sol.problem
    
      if @problem.tests.any? {|t| not t.points.nil?}
        points = nil # will be nil unless any passed test has assigned some points to us
        @run.tests.each do |run_test|
          prob_test = @problem.tests.find {|t| t.ord == run_test.test_ord }
          if prob_test.nil?
            puts "VERY VERY BAD"
            puts({'@problem.tests' => @problem.tests, 'run_test' => run_test}.to_yaml)
            return
          end
          unless prob_test.points.nil?
            points ||= 0
            if run_test.outcome == 'ok'
              pts_for_test = prob_test.points.to_i 
            else
              pts_for_test = 0
            end
            run_test.points = pts_for_test
            run_test.save!
            points += pts_for_test
          end
        end
    
        @run.points = points
      end
    
      @run.state = 4
      @run.state_assigned_at = Time.now
      @run.save!
    end
    
    puts "DONE WITH RUN #{@run.id}"
  end
end

class TesterServer
  include DRb::DRbUndumped
  
  attr_reader :clients
  
  def initialize
    @clients = {}
    @clients.extend(MonitorMixin)
    @runs_queue = []
    @jobs = []
    pickup_stale_runs
    @thread = Thread.new { self.async_loop }
  end
  
  def get_status
    return {:status => :ok}
  end
  
  def add_job(job)
    @clients.synchronize do
      @jobs << job
    end
  end
  
  def pickup_stale_runs
    tested_runs = Run.find(:all, :conditions => ['state = 3'])
    tested_runs.each do |run|
      add_job(SetPointsJob.new(self, run))
    end
    Run.connection.execute "update #{Run.table_name} set state = 0 where state = 1 or state = 2"
  end
  
  class DirInfo
    attr_reader :name, :tests, :leftover
    
    def initialize(name)
      @name = name
      @tests = {}
      @leftover = []
    end
    
    def test(position)
      @tests[position] ||= TestInfo.new(position)
    end
  end
  
  class TestInfo
    attr_accessor :input, :answer
    attr_reader :position
    
    def initialize(position)
      @position = position
    end
  end
  
  def preprocess_tests_zip(tests_upload, fname)
    puts "preprocessing #{fname}"
    dirs = 
    tests = {}
    non_tests = []
	  Zip::ZipFile.open(fname) do |zip|
	    zip.each do |entry|
	      next unless entry.file?
		    puts entry.name
        dir = (dirs[entry.parent_as_string] ||= DirInfo.new(entry.parent_as_string))
				case entry.name
				when %r!(?:^|/)(\d+)(\.in)?$!
				  dir.test($1.to_i).input = entry.name
				when %r!(?:^|/)(\d+)(\.out|\.ans|\.a)$!
				  dir.test($1.to_i).answer = entry.name
	      else
	        dir.leftover << entry.name
				end
      end
    end
  end
  
  def start_processing_tests_upload(upload_id)
    Thread.new do 
      begin
		    tests_upload = TestsUpload.find(upload_id)
        fname = File.join(UJUDGE_ROOT, tests_upload.filename)
        case tests_upload.state
        when 1
          preprocess_tests_zip(tests_upload, fname)
        when 3
          process_tests_zip(tests_upload, fname)
        end
      rescue
        puts "Exception processing zip file: #{e}"
        puts e.backtrace
      end
    end
  end
  
  def sync_tests(problem_id) 
  end
  
  def register_client(client)
    @clients.synchronize do
      proxy = @clients[client]
      return proxy.pinged unless proxy.nil?
       @clients[client] = ClientProxy.new(self, client)
    end
    puts "client registered."
  end
  
  def ping(client, state, events)
    proxy = nil
    @clients.synchronize do
      proxy = @clients[client]
      if proxy.nil?
        puts("warning: ignoring ping from unknown client") 
        return :reregister
      end
      proxy.pinged
    end
    print ","; $stdout.flush
    proxy.process_events(events)
    if state != :idle
      # Just record this.
      proxy.state = state
    else
      if proxy.run.nil?
        proxy.state = :idle
        recheck_runs
      elsif proxy.state == :sheduled
        # A run was sheduled to this client lately.
      else
        # There was a run assigned to this client, which was probably abandoned due to some
        # reason. This cannot be a client restart, because client object is still the same.
        # Anyway, this is not a normal situation. Redo this run. If this causes an infinite
        # redo loop, it's okay — better than resheduling this (possibly problematic)
        # run to different clients.
        puts "WARNING: abandoned run found, retrying."
      end
      if proxy.run
        proxy.state = :job_sent
        return create_job(proxy)  
      else
        proxy.state = :idle
      end
    end
    return :idle
  rescue Exception => e
    puts "exception: #{e}"
    puts e.backtrace
  end
  
  def create_job(proxy)
    Judge::Solution.new(proxy.run)
  end
  
  def choose_client_for_run(run)
    @clients.each do |client, proxy|
      if proxy.alive? && proxy.idle?
        return proxy
      end
    end
    return nil
  end
  
  def recheck_runs
    @clients.synchronize do
      rq = @runs_queue.dup
      rq.each do |run|
        # puts "checking run submitted by #{run.team.name} at #{run.submitted_at.strftime('%r')}..."
        proxy = choose_client_for_run(run)
        if proxy.nil?
          # puts "no client can check this run - postponing"
          next
        end
        proxy.run = run
        proxy.state = :sheduled
        @runs_queue.delete(run)
      end
    end
  end
  
  def queue_size
    @runs_queue.size
  end
  
  def clients_count
    @clients.size
  end
  
  def async_loop
    loop {
      sleep 2
      print "."; $stdout.flush

      begin
        jobs = nil
        @clients.synchronize do
          begin
            runs = Run.find(:all, :conditions => ['state = 0'])
          rescue Exception => e
            puts "exception"
            puts e.to_s
          end
          runs.each do |run|
              puts "queuing run #{run.id} submitted by #{run.team.name} at #{run.submitted_at.strftime('%r')}..."
            @runs_queue << run
            run.state = 1
            run.state_assigned_at = Time.now
            run.save!
          end
        
          jobs = @jobs
          RAILS_DEFAULT_LOGGER.info ""
          @jobs = []
        end
      
        jobs.each do |job|
          begin
            job.run
          rescue Exception => e
            puts "Job #{job.class.name} exception: #{e}"
            puts "In #{e.backtrace}"
          end
        end
      
      # cls = @clients.synchronize { @clients.collect {|x| x} }
      # cls.each do |client|
      #   begin
      #     t = 0
      #     status = Timeout::timeout(2) do
      #       t = client.ping
      #     end
      #     puts "pong at #{t}"
      #   rescue Timeout::Error
      #     puts "error pinging client: #{e}"
      #     @clients.synchronize { @clients.delete!(client) }
      #   end
      # end
      rescue Exception => e
        puts "Main async loop exception: #{e}"
        puts "In #{e.backtrace}"
      end
    }
  end
  
end

trap("SIGINT") do
  return if $root.nil?
  puts "Shutting down."
  DRb.stop_service
end

def tester_server(options)
  options.port ||= 15837
  options.host ||= 'localhost'
  $root = TesterServer.new
  uri = "druby://#{options.host}:#{options.port}"
  s = DRb.start_service(uri, $root)
  options.port ||= $1.to_i if s.uri =~ /:(\d+)$/
  
  puts "Started tester server at #{s.uri}" # IP is #{get_local_ip}."
  DRb.thread.join
end
