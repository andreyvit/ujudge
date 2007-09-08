require File.dirname(__FILE__) + '/../test_helper'
require 'testing_queues_controller'

# Re-raise errors caught by the controller.
class TestingQueuesController; def rescue_action(e) raise e end; end

class TestingQueuesControllerTest < Test::Unit::TestCase
  fixtures :testing_queues

  def setup
    @controller = TestingQueuesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
