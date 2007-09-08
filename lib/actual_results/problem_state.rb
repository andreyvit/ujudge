
module ActualResults
	class ProblemState
	  
	  attr_reader :id
	  attr_accessor :tests
	  
	  def initialize(problem_id)
	    @id = problem_id
	    @tests = Set.new
	  end
	  
	  def add_test(test)
	    @tests << test.test_ord
	  end
    
	end
end
