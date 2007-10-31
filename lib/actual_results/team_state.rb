
module ActualResults
 class TeamState
	  attr_reader :id
	  attr_reader :submittions
    attr_reader :solved_problems
    attr_reader :penalty_time
    attr_reader :points
    attr_reader :compilation_errors
	  
	  def initialize(team_id)
	    @id = team_id
	    @submittions = {}
	    @points = 0
	    @compilation_errors = 0
	  end
	  
	  def add_run(run, state)
	    submittion = (@submittions[run.problem_id] ||= SubmittionState.new(run.problem_id))
	    submittion.add_run(run, state)
	  end
	  
	  def finalize!(state)
	    @result_known = true
      @attention_required = false
      @solved_problems = 0
      @penalty_time = 0
	    
	    @submittions.each do |problem_id, submittion|
	      submittion.finalize!(state)
	    end
      
	    @submittions.each do |k, submittion|
	      @solved_problems += 1 if submittion.succeeded?
        @penalty_time += submittion.penalty_time
        @result_known = false unless submittion.result_known?
        @attention_required = true if submittion.attention_required?
        @points += submittion.points
        @compilation_errors += 1 if submittion.compilation_error?
	    end
	  end

    def result_known?; @result_known; end
    def attention_required?; @attention_required; end
    	  
	end
end
