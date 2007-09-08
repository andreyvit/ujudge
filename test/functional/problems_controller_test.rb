require File.dirname(__FILE__) + '/../test_helper'
require 'problems_controller'

# Re-raise errors caught by the controller.
class ProblemsController; def rescue_action(e) raise e end; end

class ProblemsControllerTest < Test::Unit::TestCase
  def setup
    @controller = ProblemsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
