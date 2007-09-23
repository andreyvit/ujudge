
class Judge::Solution
  attr_reader :id, :source_file, :compiler, :problem, :rules
  attr_accessor :source_text
  
  def initialize(run)
    @id = run.id
    contest = run.problem.contest
    @source_file = File.join(contest.short_name, 'solutions', run.file_name)
    @problem = ::Judge::Problem.new(run.problem)
    @rules = contest.rules
    
    @compiler = Judge::Client::NativeExecutableCompiler.new(run.compiler)
  end
  
  def unique_name(context)
    "run#{id}"
  end
end
