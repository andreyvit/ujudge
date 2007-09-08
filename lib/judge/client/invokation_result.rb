
class Judge::Client::InvokationResult
  attr_accessor :reason, :output, :stats, :exitcode
  
  def initialize
    @stats = {}
  end
  
  def ok?
    @reason == :ok
  end
end
