require File.dirname(__FILE__) + '/../test_helper'
require 'team_ratings_controller'

# Re-raise errors caught by the controller.
class TeamRatingsController; def rescue_action(e) raise e end; end

class TeamRatingsControllerTest < Test::Unit::TestCase
  def setup
    @controller = TeamRatingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
