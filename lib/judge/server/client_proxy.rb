
class Judge::Server::ClientProxy
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
    @server.add_job(Judge::Server::SetPointsJob.new(@server, run))
    banner "DONE TESTING"
    all_done
  end
  
  def all_done
    # ActualResults::CalculatedRating.invalidate(@run.team.contest)
    @server.schedule_rating_recalc(@run.team.contest_id)
    @run = nil # hurra, done!
  end
end
