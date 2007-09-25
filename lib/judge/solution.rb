
class Judge::Solution
  attr_reader :id, :source_file, :compiler, :problem, :rules, :tests_filter
  attr_accessor :source_text
  
  def initialize(run)
    @id = run.id
    contest = run.problem.contest
    @source_file = File.join(contest.short_name, 'solutions', run.file_name)
    @problem = ::Judge::Problem.new(run.problem)
    @rules = contest.rules
    @tests_filter = if run.tests_filter.nil? then nil else run.tests_filter.split(',').collect { |t| t.strip.to_i } end
    @compiler = Judge::Client::NativeExecutableCompiler.new(run.compiler)
  end
  
  def unique_name(context)
    "run#{id}"
  end
  
  def should_check_on_test?(test_ord)
    if @tests_filter.nil?
      true
    else
      @tests_filter.include?(test_ord)
    end
  end
  
end
