
class Judge::LogReporter
  
  def initialize(logger)
    @log = logger
  end
  
  def start(solution)
    @log.puts "start processing of #{solution.unique_name(:global)}"
  end
  
  def compiling
    @log.puts "compiling"
  end
  
  def compilation_error(output)
    @log.puts "compilation error, compiler output is:"
    @log.puts output
  end
  
  def testing(test)
    @log.puts "testing on test #{test.unique_name(:solution)}"
  end
  
  def invokation_error(reason)
    @log.puts "invokation error: #{reason}"
  end
  
  def invokation_finished(stats)
    @log.puts "invokation finished."
  end
  
  def checking
    @log.puts "checking"
  end
  
  def checking_problem(reason)
    @log.puts "checker problem: #{reason}."
  end
  
  def checking_finished(result, stats)
    @log.puts "checking done: #{result}."
  end

  def finished
    @log.puts "finished."
  end
  
end
