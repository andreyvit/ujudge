require File.dirname(__FILE__) + '/../test_helper'
require 'fields_controller'

# Re-raise errors caught by the controller.
class FieldsController; def rescue_action(e) raise e end; end

class FieldsControllerTest < Test::Unit::TestCase
  fixtures :fields

  def setup
    @controller = FieldsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = fields(:first).id
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

    assert_not_nil assigns(:fields)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:field)
    assert assigns(:field).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:field)
  end

  def test_create
    num_fields = Field.count

    post :create, :field => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_fields + 1, Field.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:field)
    assert assigns(:field).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Field.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Field.find(@first_id)
    }
  end
end
