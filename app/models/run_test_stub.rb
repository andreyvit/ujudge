class RunTestStub
  attr_reader :successes_exist
  
  def initialize(options = {})
    @successes_exist = options[:successes_exist]
    @outcome = options[:outcome] || 'no_solution'
  end
  
  attr_reader :partial_answer
  attr_accessor :outcome
end