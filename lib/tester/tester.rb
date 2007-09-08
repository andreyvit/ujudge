
require 'file_utils'
require 'tester/invoker'
require 'tester/checking'
require 'tester/compiler'

class SimpleLogger
  def puts(*args)
    Kernel.puts(*args)
  end
end

class Tester
  
  def initialize()
    @wdir1 = WorkingDirectory.new(File.join(UJUDGE_ROOT, 'tmp', 'wd1'))
    @wdir2 = WorkingDirectory.new(File.join(UJUDGE_ROOT, 'tmp', 'wd2'))
    @invoker = Judge::Invoker.new
    @log = SimpleLogger.new
  end
  
  def compile_and_evaluate(reporter, solution)
    fn = solution.source_file.resolve
    if !File.file?(fn) && solution.source_text
      File.open(fn, 'w') { |f| f.write(solution.source_text) }
    end
    
    reporter.start(solution)
    
    @wdir1.clean! # do this now — predict_target might try to find something in the working directory
    
    target_bundle = solution.compiler.predict_target(solution.source_file.resolve, @wdir1.path, 'solution')
    target_bundle.delete if target_bundle.exists?

    reporter.compiling
    @invoker.reset!
    # TODO: setup invoker for safe compilation
    res = solution.compiler.compile(solution.source_file.resolve, target_bundle, @wdir1, @invoker)
    return reporter.compilation_error(res[:output]) if res[:status] != :ok
    
    problem = solution.problem
    problem.tests.sort { |a,b| a.ord <=> b.ord }.each do |test|
      reporter.testing(test)
      
      @wdir2.clean!
      @invoker.reset!
      # TODO: setup invoker for safe solution invokation
      @invoker.time_limit = problem.time_limit
      @invoker.memory_limit = problem.memory_limit
      File.copy(test.input_file.resolve, @wdir2.path_of(problem.input_file_name))
      data = target_bundle.copy_runnable_to_wdir(@wdir2)
      res = target_bundle.run_from_wdir(data, @wdir2, @invoker)
      
      unless res.ok?
        reporter.invokation_error(res.reason)
        break #next
      end
      
      reporter.invokation_finished(res.stats)
      
      output_file_path = @wdir2.path_of(problem.output_file_name)
      unless File.file?(output_file_path)
        reporter.checking_finished(:no_output_file, OpenStruct.new)
        break #next
      end
      
      reporter.checking
      
      @invoker.reset!
      # TODO: setup invoker for safe checker invokation
      res = problem.checker.check(test, output_file_path, @wdir2, @invoker)
      unless res.status == :ok
        reporter.checking_problem(res.status)
        break #next
      end
      
      reporter.checking_finished(res.outcome, res)

      break unless res.outcome == :ok
    end
    
    reporter.finished
  end
  
end

