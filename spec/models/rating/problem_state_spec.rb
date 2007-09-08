require File.dirname(__FILE__) + '/../../spec_helper'

context "An empty problem state" do
  
  setup do
    @problem_state = ActualResults::ProblemState.new(42)
    @test = mock("test")
  end
  
  specify "should have the specified problem id" do
    @problem_state.id.should == 42
  end
  
  specify "should have no tests" do
    @problem_state.tests.should be_empty
  end
  
end

context "A one-test problem state" do
  
  setup do
    @problem_state = ActualResults::ProblemState.new(42)
    
    @test = mock("prev_test")
    @test.stub!(:test_ord).and_return(7)
    @problem_state.add_test(@test)
  end
  
  specify "should have exactly one test" do
    @problem_state.tests.size.should == 1
  end
  
  specify "should not add duplicates" do
    @problem_state.add_test(@test)
    @problem_state.tests.size.should == 1
  end
  
  specify "should have the correct test" do
    @problem_state.tests.should be_include(7)
  end
    
	specify "should not change when the test result is changed" do
	  orig = @problem_state.tests.to_a.dup.sort
    @test.stub!(:test_ord).and_return(8)
	  @problem_state.tests.to_a.dup.sort.should == orig 
	end
  
end
