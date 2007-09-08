require File.dirname(__FILE__) + '/../../spec_helper'

context "An empty test state" do
  
  setup do
    @test_state = ActualResults::TestState.new(42)
    @test = mock("test")
  end
  
  specify "should have the specified position" do
    @test_state.position.should == 42
  end
  
  specify "should have :not_tested outcome" do
    @test_state.outcome.should == :not_tested
  end
  
  specify "should get an outcome from test" do
    @test.should_receive(:outcome).and_return(:foo)
    @test_state.add_test(@test)
    @test_state.outcome.should == :foo
  end
  
  specify "should not be considered successful" do
    @test_state.should_not be_succeeded
  end
  
  specify "should not have an unknown result" do
    @test_state.should_not be_result_known
  end
  
  specify "should not require attention" do
    @test_state.should_not be_attention_required
  end

end

context "A non-empty test state" do
  
  setup do
    @test_state = ActualResults::TestState.new(42)
    
    @prev_test = mock("prev_test")
    @prev_test.stub!(:outcome).and_return(:foo)
    @test_state.add_test(@prev_test)
    
    @new_test = mock("test")
  end
  
  specify "should have a correct outcome" do
    @test_state.outcome.should == :foo
  end
    
	specify "should not change outcome when the test result is changed" do
	  @prev_test.stub!(:outcome).and_return(:boz)
	  @test_state.outcome.should == :foo
	end
    
  specify "should override an outcome from test" do
    @new_test.should_receive(:outcome).and_return(:bar)
    @test_state.add_test(@new_test)
    @test_state.outcome.should == :bar
  end

end

context "A successful test state" do
  
  setup do
    @test_state = ActualResults::TestState.new(42)
    @test = mock("test")
    @test.stub!(:outcome).and_return(:ok)
    @test_state.add_test(@test)
  end

	specify "should be considered successful" do
	  @test_state.should be_succeeded
	end
	
	specify "should have an unknown result" do
	  @test_state.should be_result_known
	end
	
	specify "should not require attention" do
	  @test_state.should_not be_attention_required
	end
  
end

context "A failed test state" do
  
  setup do
    @test_state = ActualResults::TestState.new(42)
    @test = mock("test")
    @test.stub!(:outcome).and_return(:wrong_answer)
    @test_state.add_test(@test)
  end

	specify "should not be considered successful" do
	  @test_state.should_not be_succeeded
	end
	
	specify "should have an unknown result" do
	  @test_state.should be_result_known
	end
	
	specify "should not require attention" do
	  @test_state.should_not be_attention_required
	end
  
end

context "A problematic test state" do
  
  setup do
    @test_state = ActualResults::TestState.new(42)
    @test = mock("test")
    @test.stub!(:outcome).and_return(:internal_error)
    @test_state.add_test(@test)
  end

	specify "should not be considered successful" do
	  @test_state.should_not be_succeeded
	end
	
	specify "should not have an unknown result" do
	  @test_state.should_not be_result_known
	end
	
	specify "should require attention" do
	  @test_state.should be_attention_required
	end
  
end
