
# run stub is used during rating calculation in place of a missing run
class RunStub
  # attr_reader :points
  
  def points
    0
  end
  
  def has_test_results?
    false
  end
end