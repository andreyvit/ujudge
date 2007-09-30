
module ActualResults	
	class CalculatedRating
	  
	  attr_reader :sorted_teams
    
	  attr_reader :teams
    
    def self.cache_key(contest)
      "c#{contest.respond_to?(:id) ? contest.id : contest}-rating"
    end
	  
	  def self.get(contest, rdef, team)
	    ActualResults::TeamState
	    ActualResults::TestState
	    ActualResults::SubmittionState
	    ActualResults::ProblemState
	    Cache.get(cache_key(contest)) do 
		    returning self.new do |r|
	        r.calculate(contest, rdef, team)
		    end
      end
	  end
    
    def self.invalidate(contest)
      Cache.delete(cache_key(contest))
    end
	  
	  def initialize
	    @problems = {}
	    @teams = {}
	  end
	  
	  def calculate(contest, rdef, team)
	    runs = contest.evaluated_runs.find(:all)
	    runs.sort {|a,b| a.submitted_at <=> b.submitted_at}
	    all_teams = contest.teams.find(:all)
	    runs.delete_if do |run| all_teams.find { |t| t.id == run.team_id }.disqualified? end
	    runs.each do |run|
	      problem = (@problems[run.problem_id] ||= ProblemState.new(run.problem))
	      run.tests.each { |test| problem.add_test(test) }
	    end
	    runs.each do |run|
	      team = (@teams[run.team_id] ||= TeamState.new(run.team_id))
	      team.add_run(run)
	    end
	    @teams.each do |team_id, team|
	      team.finalize!(@problems)
	    end
      #RAILS_DEFAULT_LOGGER.info "teams: #{@teams.values.join(', ')}"
      case contest.rules
      when 'acm'
        @sorted_teams = @teams.values.sort do |a, b|
          ((b.solved_problems <=> a.solved_problems) * 10 + (a.penalty_time <=> b.penalty_time) * 4) <=> 0
        end
      when 'ioi'
        @sorted_teams = @teams.values.sort do |a, b|
          (b.points <=> a.points) * 10 + (a.compilation_errors <=> b.compilation_errors)
        end
      end
	  end
	  
	end
end
