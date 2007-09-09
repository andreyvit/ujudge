require File.dirname(__FILE__) + '/../test_helper'
require 'forms_controller'

# Re-raise errors caught by the controller.
class FormsController; def rescue_action(e) raise e end; end

class FormsControllerTest < Test::Unit::TestCase
  fixtures :forms

  def setup
    @controller = FormsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = forms(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:forms)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:form)
    assert assigns(:form).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:form)
  end

  def test_create
    num_forms = Form.count

    post :create, :form => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_forms + 1, Form.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:form)
    assert assigns(:form).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Form.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Form.find(@first_id)
    }
  end
end
