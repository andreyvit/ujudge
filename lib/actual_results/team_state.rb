
module ActualResults
 class TeamState
	  attr_reader :id
	  attr_reader :submittions
    attr_reader :solved_problems
    attr_reader :penalty_time
    attr_reader :points
	  
	  def initialize(team_id)
	    @id = team_id
	    @submittions = {}
	    @points = 0
	  end
	  
	  def add_run(run)
	    submittion = (@submittions[run.problem_id] ||= SubmittionState.new(run.problem_id))
	    submittion.add_run(run)
	  end
	  
	  def finalize!(problems)
	    @result_known = true
      @attention_required = false
      @solved_problems = 0
      @penalty_time = 0
	    
	    @submittions.each do |problem_id, submittion|
	      submittion.finalize!(problems[problem_id])
	    end
      
	    @submittions.each do |k, submittion|
	      @solved_problems += 1 if submittion.succeeded?
        @penalty_time += submittion.penalty_time
        @result_known = false unless submittion.result_known?
        @attention_required = true if submittion.attention_required?
        @points += submittion.points
	    end
	  end

    def result_known?; @result_known; end
    def attention_required?; @attention_required; end
    	  
	end
end
