
require 'drb'
require 'socket'
require 'monitor'
require 'timeout'
require 'pathname'
#require 'zip/zip'

def get_local_ip
  IPSocket.getaddress(Socket.gethostname)
end

class Judge::Server::Server
  include DRb::DRbUndumped
  
  attr_reader :clients
  
  def initialize
    @clients = {}
    @clients.extend(MonitorMixin)
    @runs_queue = []
    @jobs = []
    pickup_stale_runs
    @thread = Thread.new { self.async_loop }
    x = Judge::Client::CheckingResult
    # sol = Judge::Solution.new(Run.find(:first, :conditions => 'state IN (0, 1)'))
    # s = Marshal.dump(sol);
    # File.open(File.join(UJUDGE_ROOT, 'test.dmp'), 'w') { |f| f.write(s) }
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
      add_job(Judge::Server::SetPointsJob.new(self, run))
    end
    Run.connection.execute "update #{Run.table_name} set state = 0 where state = 1 or state = 2"
  end
  
  def start_processing_tests_upload(upload_id)
    add_job(Judge::Server::ProcessTestsUploadJob.new(self, upload_id))
  end
  
  def sync_tests(problem_id) 
  end
  
  def register_client(client)
    @clients.synchronize do
      proxy = @clients[client]
      return proxy.pinged unless proxy.nil?
       @clients[client] = Judge::Server::ClientProxy.new(self, client)
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

  def get_tests(problem_id)
    tests = Judge::Problem.new(::Problem.find(problem_id)).tests
    tests.each { |t| t.problem = nil }
    tests
  end
  
  def get_tests_count(problem_id)
    Judge::Problem.new(::Problem.find(problem_id)).tests.size
  end
  
  def create_job(proxy)
    returning Judge::Solution.new(proxy.run) do |s|
      s.problem.tests
    end
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
  
  def get_file(rel_path, remote_mtime)
    local_file = File.join(RAILS_ROOT, 'data', rel_path)
    return :not_found unless File.exists?(local_file)
    local_mtime = File.mtime(local_file)
    # consider the files the same if times differ by less than 4 seconds
    return :unchanged if remote_mtime && (local_mtime - remote_mtime).abs < 4
    data = File.open(local_file, 'rb') { |f| f.read }
    return [data, local_mtime]
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
  
  def self.start_server(options)
    trap("SIGINT") do
      return if $root.nil?
      puts "Shutting down."
      DRb.stop_service
    end
    
    options.port ||= 15837
    options.host ||= 'localhost'
    $root = self.new
    uri = "druby://#{options.host}:#{options.port}"
    s = DRb.start_service(uri, $root)
    options.port ||= $1.to_i if s.uri =~ /:(\d+)$/

    puts "Started tester server at #{s.uri}" # IP is #{get_local_ip}."
    DRb.thread.join
  end
  
end

