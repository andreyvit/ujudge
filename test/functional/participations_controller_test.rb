require File.dirname(__FILE__) + '/../test_helper'
require 'participations_controller'

# Re-raise errors caught by the controller.
class ParticipationsController; def rescue_action(e) raise e end; end

class ParticipationsControllerTest < Test::Unit::TestCase
  fixtures :participations

  def setup
    @controller = ParticipationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
