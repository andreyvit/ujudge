require File.dirname(__FILE__) + '/../../spec_helper'

context "The CalculatedRating" do
  
  def at(n)
    Time.mktime(2007, 4, 8, 14, n)
  end
  
  setup do
    @rating = ActualResults::CalculatedRating.new
    @contest = mock("contest")
    @rating_definition = mock("rating_definition")
    @team = mock("team")
    
    @run1 = mock("run1")
    @run2 = mock("run2")
    @run3 = mock("run3")
    
    @run1.stub!(:submitted_at).and_return(at(1))
    @run1.stub!(:problem_id).and_return(1)
    
    @run1t1 = mock("test1.1")
    @run1t1.stub!(:test_ord).and_return(1)
    @run1.stub!(:tests).and_return([@run1t1])
    
    @run2.stub!(:submitted_at).and_return(at(3))
    @run2.stub!(:problem_id).and_return(1)
    
    @run2t1 = mock("test2.1")
    @run2t1.stub!(:test_ord).and_return(1)
    @run2.stub!(:tests).and_return([@run2t1])
    
    @run3.stub!(:submitted_at).and_return(at(2))
    @run3.stub!(:problem_id).and_return(2)
    
    @run3t1 = mock("test3.1")
    @run3t1.stub!(:test_ord).and_return(1)
    @run3.stub!(:tests).and_return([@run3t1])
    
    @runs = [@run1, @run2, @run3]
  end
  
  specify "should calculate a simple rating" do
    @contest.should_receive(:evaluated_runs).and_return(@runs)
    @rating.calculate(@contest, @rating_definition, @team)
  end

end
