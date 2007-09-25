
class Retesting
  
  attr_accessor :tests, :problems, :compilers, :scope
  
  attr_reader :errors
  
  def initialize
    @errors = Object.new
    class << @errors
      def on(id)
        nil
      end
    end
    
    @problems = []
    @compilers = []
    @scope = 'all'
  end
  
end
