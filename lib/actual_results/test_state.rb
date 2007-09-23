
module ActualResults
	class TestState
	  
	  attr_reader :position
	  attr_reader :outcome
	  attr_accessor :points
	  
	  def initialize(position)
	    @position = position
      @outcome = :not_tested
	  end
	  
	  def add_test(test) 
	    @outcome = test.outcome.intern
	    @points = test.points
	  end
    
    def succeeded?
      return :ok == @outcome
    end
    
    def result_known?
      return !attention_required? && :not_tested != @outcome
    end
    
    def attention_required?
      return [:internal_error, :run_failure, :failure].include?(@outcome)
    end
	  
	end
end