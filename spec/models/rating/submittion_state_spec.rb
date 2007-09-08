require File.dirname(__FILE__) + '/../../spec_helper'

context "An empty submittion state" do
  
  setup do
    @submittion_state = ActualResults::SubmittionState.new(42)
    @test = mock("test")
  end
  
  specify "should have the specified problem id" do
    @submittion_state.problem_id.should == 42
  end
  
  specify "should have no tests" do
    @submittion_state.tests.should be_empty
  end
  
end

context "A one-test submittion state" do
  
  setup do
    @submittion_state = ActualResults::SubmittionState.new(42)
    
    @test_state_1 = mock("test_state_1")
    @test_state_1.stub!(:position).and_return(7)
    ActualResults::TestState.stub!(:new).and_return(@test_state_1)
    
    @test = mock("test")
    @test.stub!(:test_ord).and_return(7)
    
    @run = mock("run")
    @run.stub!(:tests).and_return([@test])
    @run.stub!(:penalty_time).and_return(180)
    
    @test_state_1.stub!(:add_test)
    @submittion_state.add_run(@run)
  end
  
  specify "should have exactly one test" do
    @submittion_state.tests.size.should == 1
  end
  
  specify "should not add duplicates" do
		@run2 = mock("run2")
		@run2.stub!(:tests).and_return([@test])
    @run2.stub!(:penalty_time).and_return(210)
        
    @test_state_1.should_receive(:add_test).with(@test)
    		 
		@submittion_state.add_run(@run2)
    @submittion_state.tests.size.should == 1
  end
  
  specify "should have the correct test" do
    @submittion_state.tests.should == {7 => @test_state_1}
  end
    
end

context "A finalized submittion state for a failed submittion" do
  
  setup do
    @submittion_state = ActualResults::SubmittionState.new(42)
    
    @test_state_1 = mock("test_state_1")
    @test_state_1.stub!(:position).and_return(7)
    @test_state_1.stub!(:succeeded?).and_return(true)
    @test_state_1.stub!(:result_known?).and_return(true)
    @test_state_1.stub!(:attention_required?).and_return(false)
        
    @test_state_2 = mock("test_state_2")
    @test_state_2.stub!(:position).and_return(9)
    @test_state_2.stub!(:succeeded?).and_return(false)
    @test_state_2.stub!(:result_known?).and_return(true)
    @test_state_2.stub!(:attention_required?).and_return(false)
    
    ActualResults::TestState.should_receive(:new).with(7).and_return(@test_state_1)
    ActualResults::TestState.should_receive(:new).with(9).and_return(@test_state_2)
    
    @test1 = mock("test1")
    @test1.stub!(:test_ord).and_return(7)
    
    @test2 = mock("test2")
    @test2.stub!(:test_ord).and_return(9)
    
    @run = mock("run")
    @run.stub!(:tests).and_return([@test1, @test2])
    @run.stub!(:penalty_time).and_return(180)
        
    @test_state_1.should_receive(:add_test).with(@test1)
    @test_state_2.should_receive(:add_test).with(@test2)
    @submittion_state.add_run(@run)
    
    @test_state_3 = mock("test_state_3")
    @test_state_3.stub!(:succeeded?).and_return(false)
    @test_state_3.stub!(:result_known?).and_return(false)
    @test_state_3.stub!(:attention_required?).and_return(false)
    
    @problem_state = mock("problem_state")
    @problem_state.should_receive(:tests).and_return([7, 9, 11])
    
    ActualResults::TestState.should_receive(:new).with(11).and_return(@test_state_3)
    @submittion_state.finalize!(@problem_state)
  end
  
  specify "should have the correct number of tests" do
    @submittion_state.tests.size.should == 3
  end
  
  specify "should include the untested tests" do
    @submittion_state.tests.should == {7 => @test_state_1, 9 => @test_state_2, 11 => @test_state_3}
  end
  
  specify "should be marked as failed" do
    @submittion_state.should_not be_succeeded
  end
  
  specify "should calculate the number of passed tests" do
    @submittion_state.passed_tests.should == 1
  end
  
  specify "should have a known result" do
    @submittion_state.should be_result_known
  end
  
  specify "should not require attention" do
    @submittion_state.should_not be_attention_required
  end
  
end

context "A finalized submittion state for a successful submittion with an untested test" do
  
  setup do
    @submittion_state = ActualResults::SubmittionState.new(42)
    
    @test_state_1 = mock("test_state_1")
    @test_state_1.stub!(:position).and_return(7)
    @test_state_1.stub!(:succeeded?).and_return(true)
    @test_state_1.stub!(:result_known?).and_return(true)
    @test_state_1.stub!(:attention_required?).and_return(false)
            
    @test_state_2 = mock("test_state_2")
    @test_state_2.stub!(:position).and_return(9)
    @test_state_2.stub!(:succeeded?).and_return(true)
    @test_state_2.stub!(:result_known?).and_return(true)
    @test_state_2.stub!(:attention_required?).and_return(false)
    
    ActualResults::TestState.should_receive(:new).with(7).and_return(@test_state_1)
    ActualResults::TestState.should_receive(:new).with(9).and_return(@test_state_2)
    
    @test1 = mock("test1")
    @test1.stub!(:test_ord).and_return(7)
    
    @test2 = mock("test2")
    @test2.stub!(:test_ord).and_return(9)
    
    @run = mock("run")
    @run.stub!(:tests).and_return([@test1, @test2])
    @run.stub!(:penalty_time).and_return(180)
        
    @test_state_1.should_receive(:add_test).with(@test1)
    @test_state_2.should_receive(:add_test).with(@test2)
    @submittion_state.add_run(@run)
    
    @test_state_3 = mock("test_state_3")
    @test_state_3.stub!(:succeeded?).and_return(false)
    @test_state_3.stub!(:result_known?).and_return(false)
    @test_state_3.stub!(:attention_required?).and_return(false)
        
    @problem_state = mock("problem_state")
    @problem_state.should_receive(:tests).and_return([7, 9, 11])
    
    ActualResults::TestState.should_receive(:new).with(11).and_return(@test_state_3)
    @submittion_state.finalize!(@problem_state)
  end
  
  specify "should have the correct number of tests" do
    @submittion_state.tests.size.should == 3
  end
  
  specify "should have the correct tests" do
    @submittion_state.tests.should == {7 => @test_state_1, 9 => @test_state_2, 11 => @test_state_3}
  end
    
	specify "should be marked as failed" do
	  @submittion_state.should_not be_succeeded
	end
   
	specify "should calculate the number of passed tests" do
	  @submittion_state.passed_tests.should == 2
	end
	
	specify "should not have a known result" do
	  @submittion_state.should_not be_result_known
	end
	
	specify "should not require attention" do
	  @submittion_state.should_not be_attention_required
	end
      
end

context "A finalized submittion state for a successful submittion" do
  
  setup do
    @submittion_state = ActualResults::SubmittionState.new(42)
    
    @test_state_1 = mock("test_state_1")
    @test_state_1.stub!(:position).and_return(7)
    @test_state_1.stub!(:succeeded?).and_return(true)
    @test_state_1.stub!(:result_known?).and_return(true)
    @test_state_1.stub!(:attention_required?).and_return(false)
            
    @test_state_2 = mock("test_state_2")
    @test_state_2.stub!(:position).and_return(9)
    @test_state_2.stub!(:succeeded?).and_return(true)
    @test_state_2.stub!(:result_known?).and_return(true)
    @test_state_2.stub!(:attention_required?).and_return(false)
    
    ActualResults::TestState.should_receive(:new).with(7).and_return(@test_state_1)
    ActualResults::TestState.should_receive(:new).with(9).and_return(@test_state_2)
    
    @test1 = mock("test1")
    @test1.stub!(:test_ord).and_return(7)
    
    @test2 = mock("test2")
    @test2.stub!(:test_ord).and_return(9)
    
    @run = mock("run")
    @run.stub!(:tests).and_return([@test1, @test2])
    @run.stub!(:penalty_time).and_return(180)
        
    @test_state_1.should_receive(:add_test).with(@test1)
    @test_state_2.should_receive(:add_test).with(@test2)
    @submittion_state.add_run(@run)
    
    @problem_state = mock("problem_state")
    @problem_state.should_receive(:tests).and_return([7, 9])
    
    @submittion_state.finalize!(@problem_state)
  end
  
  specify "should have the correct number of tests" do
    @submittion_state.tests.size.should == 2
  end
  
  specify "should have the correct tests" do
    @submittion_state.tests.should == {7 => @test_state_1, 9 => @test_state_2}
  end
  
	specify "should be marked as succeeded" do
	  @submittion_state.should be_succeeded
	end
     
	specify "should calculate the number of passed tests" do
	  @submittion_state.passed_tests.should == 2
	end
	
	specify "should have a known result" do
	  @submittion_state.should be_result_known
	end
	
	specify "should not require attention" do
	  @submittion_state.should_not be_attention_required
	end
      
end
