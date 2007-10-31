
module ActualResults	
	class IntermediateState
	  
	  attr_accessor :problems_by_id
	  
	  def initialize
	    @problems_by_id = {}
    end
    
    def add_problem!(problem)
      @problems_by_id[problem.id] = ProblemState.new(problem)
    end
	  
  end
end

