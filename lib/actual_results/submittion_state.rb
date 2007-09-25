
module ActualResults
  class SubmittionState
      
	  attr_reader :problem_id
	  attr_reader :tests
    attr_reader :passed_tests
    attr_reader :attemps
    attr_reader :penalty_time
    attr_reader :last_run_time
    attr_reader :points
    	  
	  def initialize(problem_id)
	    @problem_id = problem_id
	    @tests = {}
      @attemps = 0
      @last_run_time = 0
      @ignore_others = false
      @compilation_error = false
      @no_compilation_errors_megahack = false
      @points = 0
	  end
	  
	  def add_run(run)
	    return if @ignore_others
	    return unless run.state >= 3
	    @attemps += 1
      @last_run_time = run.penalty_time
	    run.tests.each do |test|
	      my_test = (@tests[test.test_ord] ||= TestState.new(test.test_ord))
	      my_test.add_test(test)
	    end
	    # determine 
      @compilation_error = (run.outcome == 'compilation-error')
      @no_compilation_errors_megahack = true unless @compilation_error
      
      # determine which tests passed, because if the problem is accepted (in ACM mode)
      # we want to ignore any additional results
      self.finalize!
      @ignore_others = true if @succeeded
	  end
	  
	  def finalize!(problem = nil)
	    @compilation_error = false if @no_compilation_errors_megahack
	    Judge::Problem.new(Problem.find(@problem_id)).tests.each do |test|
	      @tests[test.ord] ||= TestState.new(test.ord)
	    end
	    @passed_tests = 0
      if @tests.empty?
	      @succeeded = false
	      @result_known = false
	      @attention_required = true
        @passed_tests = 0
      else
        @succeeded = true
        @result_known = true
        @attention_required = false
        sorted_tests = @tests.sort.collect {|pair| pair.last}
        problem.per_test_dependencies.each do |dependent_test, dependencies|
          some_required_tests_succeded = catch(:some_required_tests_succeded) do
            dependencies.each do |dependency|
              throw :some_required_tests_succeded, true if @tests[dependency].succeeded?
            end
            throw :some_required_tests_succeded, false
          end
          @tests[dependent_test].points = 0 unless some_required_tests_succeded || @tests[dependent_test].points.nil?
        end
        sorted_tests.each_with_index do |test, test_index|
          @passed_tests += 1 if test.succeeded?
          @points += test.points.to_i if test.succeeded? && !test.points.nil?
          RAILS_DEFAULT_LOGGER.info "team #{self}, problem #{@problem_id}, ord #{test_index}, res #{test.succeeded? ? "ok" : "notok"}"
          @result_known = false unless !@succeeded || test.result_known?
          @succeeded = false unless test.succeeded?
          @attention_required = true if test.attention_required?
        end
      end
      if !@succeeded
        @penalty_time = 0
      else
        @penalty_time = @last_run_time + 20 * (@attemps - 1)
      end
	  end
    
    def succeeded?; @succeeded; end
    def result_known?; @result_known; end
    def attention_required?; @attention_required; end
    def compilation_error?; @compilation_error; end
      
  end
end
