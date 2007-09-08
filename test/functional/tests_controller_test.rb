require File.dirname(__FILE__) + '/../test_helper'
require 'tests_controller'

# Re-raise errors caught by the controller.
class TestsController; def rescue_action(e) raise e end; end

class TestsControllerTest < Test::Unit::TestCase
  fixtures :tests

  def setup
    @controller = TestsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:tests)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_tests
    old_count = Tests.count
    post :create, :tests => { }
    assert_equal old_count+1, Tests.count
    
    assert_redirected_to tests_path(assigns(:tests))
  end

  def test_should_show_tests
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_tests
    put :update, :id => 1, :tests => { }
    assert_redirected_to tests_path(assigns(:tests))
  end
  
  def test_should_destroy_tests
    old_count = Tests.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Tests.count
    
    assert_redirected_to tests_path
  end
end
