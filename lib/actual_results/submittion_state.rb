
module ActualResults
  class SubmittionState
      
	  attr_reader :problem_id
	  attr_reader :tests
    attr_reader :passed_tests
    attr_reader :attemps
    attr_reader :penalty_time
    attr_reader :last_run_time
    	  
	  def initialize(problem_id)
	    @problem_id = problem_id
	    @tests = {}
      @attemps = 0
      @last_run_time = 0
      @ignore_others = false
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
      self.finalize!
      @ignore_others = true if @succeeded
	  end
	  
	  def finalize!(problem = nil)
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
        sorted_tests.each do |test|
          @passed_tests += 1 if test.succeeded?
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
      
  end
end
