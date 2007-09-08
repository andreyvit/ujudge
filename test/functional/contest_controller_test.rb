require File.dirname(__FILE__) + '/../test_helper'
require 'contest_controller'

# Re-raise errors caught by the controller.
class ContestController; def rescue_action(e) raise e end; end

class ContestControllerTest < Test::Unit::TestCase
  def setup
    @controller = ContestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
