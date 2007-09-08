
class Judge::Test
  attr_reader :problem, :ord, :input_file, :answer_file
  attr_accessor :points
  
  def initialize(problem, ord, input_file_name, answer_file_name)
    @problem = problem
    @ord = ord
    @input_file  = File.join(@problem.fspath, input_file_name)
    puts input_file_name
    @answer_file = File.join(@problem.fspath, answer_file_name)
  end
  
  def unique_name(context)
    "#{@problem.unique_name(context)}.test#{sprintf("%02d", @ord)}"
  end
end  
