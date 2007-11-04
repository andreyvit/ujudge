
class Judge::Client::Tester
  
  def initialize()
    @wdir1 = WorkingDirectory.new(File.join(UJUDGE_ROOT, 'tmp', 'wd1'))
    @wdir2 = WorkingDirectory.new(File.join(UJUDGE_ROOT, 'tmp', 'wd2'))
    @invoker = Invoker.new
  end
  
  def compile_and_evaluate(reporter, solution, vfs)
    local_solution_file = vfs.try_to_get(solution.source_file)
    if local_solution_file.nil?
        return reporter.compilation_error("Source file not found: #{solution.source_file}")
    end
    
    reporter.start(solution)
    
    @wdir1.clean! # do this now — predict_target might try to find something in the working directory
    
    target_bundle = solution.compiler.predict_target(local_solution_file, @wdir1.path, 'solution')
    target_bundle.delete if target_bundle.exists?

    reporter.compiling
    @invoker.reset!
    # TODO: setup invoker for safe compilation
    res = solution.compiler.compile(local_solution_file, target_bundle, @wdir1, @invoker)
    return reporter.compilation_error(res[:output]) if res[:status] != :ok
    
    problem = solution.problem
    problem.tests.sort { |a,b| a.ord <=> b.ord }.each do |test|
      next unless solution.should_check_on_test?(test.ord)
      id = catch(:end_test) do
        reporter.testing(test)
      
        @wdir2.clean!

        # copy input file to working dir
        local_input_file = vfs.get(test.input_file)
        File.copy(local_input_file, @wdir2.path_of(problem.input_file_name))

        @invoker.reset!
        # TODO: setup invoker for safe solution invokation
        @invoker.time_limit = problem.time_limit
        @invoker.memory_limit = problem.memory_limit
        data = target_bundle.copy_runnable_to_wdir(@wdir2)
        res = target_bundle.run_from_wdir(data, @wdir2, @invoker)
      
        unless res.ok?
          reporter.invokation_error(res.reason)
          end_test(solution)
        end
      
        reporter.invokation_finished(res.stats)
      
        output_file_path = @wdir2.path_of(problem.output_file_name)
        unless File.file?(output_file_path)
          reporter.checking_finished(:no_output_file, OpenStruct.new)
          end_test(solution)
        end
      
        reporter.checking
      
        @invoker.reset!
        # TODO: setup invoker for safe checker invokation
        res = problem.checker.check(test, local_input_file, output_file_path, @wdir2, @invoker, vfs)
        unless res.status == :ok
          reporter.checking_problem(res.status)
          end_test(solution)
        end
      
        reporter.checking_finished(res.outcome, res)

        end_test(solution) unless res.outcome == :ok
      end
      case id
      when :break then break
      when :next then next
      end
    end
    
    reporter.finished
  end
  
private

  def end_test(solution)
    case solution.rules
    when 'acm'
      throw :end_test, :break
    when 'ioi'
      throw :end_test, :next
    end
  end
  
end
