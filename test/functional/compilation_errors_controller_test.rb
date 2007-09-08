require File.dirname(__FILE__) + '/../test_helper'
require 'compilation_errors_controller'

# Re-raise errors caught by the controller.
class CompilationErrorsController; def rescue_action(e) raise e end; end

class CompilationErrorsControllerTest < Test::Unit::TestCase
  fixtures :compilation_errors

  def setup
    @controller = CompilationErrorsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
