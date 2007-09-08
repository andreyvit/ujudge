require File.dirname(__FILE__) + '/../test_helper'
require 'tests_uploads_controller'

# Re-raise errors caught by the controller.
class TestsUploadsController; def rescue_action(e) raise e end; end

class TestsUploadsControllerTest < Test::Unit::TestCase
  fixtures :tests_uploads

  def setup
    @controller = TestsUploadsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:tests_uploads)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_tests_upload
    old_count = TestsUpload.count
    post :create, :tests_upload => { }
    assert_equal old_count+1, TestsUpload.count
    
    assert_redirected_to tests_upload_path(assigns(:tests_upload))
  end

  def test_should_show_tests_upload
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_tests_upload
    put :update, :id => 1, :tests_upload => { }
    assert_redirected_to tests_upload_path(assigns(:tests_upload))
  end
  
  def test_should_destroy_tests_upload
    old_count = TestsUpload.count
    delete :destroy, :id => 1
    assert_equal old_count-1, TestsUpload.count
    
    assert_redirected_to tests_uploads_path
  end
end
