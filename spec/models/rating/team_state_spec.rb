require File.dirname(__FILE__) + '/../../spec_helper'

context "An empty team state" do
  
  setup do
    @team_state = ActualResults::TeamState.new(42)
    @test = mock("test")
  end
  
  specify "should have the specified team id" do
    @team_state.id.should == 42
  end
  
  specify "should have no submittions" do
    @team_state.submittions.should be_empty
  end
  
  specify "should delegate add_run to a newly created solution state" do
    @run = mock("run")
    @run.stub!(:problem_id).and_return(21)
    
    @submittion_state = mock("submittion_state")
    @submittion_state.should_receive(:add_run).with(@run)
    
    ActualResults::SubmittionState.should_receive(:new).with(21).and_return(@submittion_state)
    @team_state.add_run(@run)
  end
  
end

context "A team state after adding a run" do
  
  setup do
    @team_state = ActualResults::TeamState.new(42)
    
    @submittion_state_1 = mock("submittion_state_1")
    ActualResults::SubmittionState.stub!(:new).and_return(@submittion_state_1)
    
    @run = mock("run")
    @run.stub!(:problem_id).and_return(21)
    
    @submittion_state_1.stub!(:add_run)
    @submittion_state_1.stub!(:succeeded?).and_return(true)
    @submittion_state_1.stub!(:result_known?).and_return(true)
    @submittion_state_1.stub!(:attention_required?).and_return(false)
    @submittion_state_1.stub!(:penalty_time).and_return(420)
    
    @team_state.add_run(@run)
  end
  
  specify "should have exactly one submittion" do
    @team_state.submittions.size.should == 1
  end
  
  specify "should have the correct submittion" do
    @team_state.submittions.should == {21 => @submittion_state_1}
  end
  
  specify "should delegate finalize! to it's submittion" do
    @problem_state = mock("problem_state")
    @problems = mock("problems")
    @problems.should_receive(:[]).with(21).and_return(@problem_state)
    @submittion_state_1.should_receive(:finalize!).with(@problem_state)
    @team_state.finalize!(@problems)
  end
    
end
