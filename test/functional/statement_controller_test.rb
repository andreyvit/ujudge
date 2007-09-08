require File.dirname(__FILE__) + '/../test_helper'
require 'statement_controller'

# Re-raise errors caught by the controller.
class StatementController; def rescue_action(e) raise e end; end

class StatementControllerTest < Test::Unit::TestCase
  def setup
    @controller = StatementController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
