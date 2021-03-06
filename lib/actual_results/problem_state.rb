
module ActualResults
	class ProblemState
	  
	  attr_reader :id
	  attr_reader :per_test_dependencies
	  
	  def initialize(problem)
	    @id = problem.id
	    @problem_def = Judge::Problem.new(problem)
	    @per_test_dependencies = {}
	    (problem.test_dependencies || '').split(';').collect(&:strip).each do |rule|
	      lhs, rhs = rule.split('if', 2).collect(&:strip)
	      rhs = self.class.parse_items(rhs)
        self.class.parse_items(lhs).each do |dependent_test|
          raise "Duplicated dependent tests" if @per_test_dependencies[dependent_test]
          @per_test_dependencies[dependent_test] = rhs
        end
	    end
	  end
	  
	  def tests
	    @problem_def.tests
    end
  
	  def self.parse_items(comma_separated_items)
	    comma_separated_items.split(',').collect(&:strip).collect do |item|
        if item =~ /^(\d+)..(\d+)$/
          ($1.to_i .. $2.to_i).to_a
        else
          item.to_i
        end
      end.flatten.sort.uniq
    end
    
	end
end
