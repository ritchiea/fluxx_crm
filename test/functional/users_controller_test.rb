require 'test_helper'

class UsersControllerTest < ActionController::TestCase

  def setup
    @user1 = User.make
    login_as @user1
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end
  
  test "should get CSV index" do
    get :index, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "autocomplete" do
    User.make
    lookup_user = User.make
    get :index, :first_name => lookup_user.first_name, :last_name => lookup_user.last_name, :format => :json
    a = @response.body.de_json # try to deserialize the JSON to an array
    assert_equal lookup_user.to_s, a.first['label']
    assert_equal lookup_user.id, a.first['value']
  end

  test "should confirm that user_exists" do
    get :index, :first_name => @user1.first_name, :format => :json
    a = @response.body.de_json # try to deserialize the JSON to an array
    assert_equal @user1.id, a.first['value']
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post :create, :user => { :first_name => 'some random name for you' }
    end

    # Figure out how to determine a 201 and the options therein; some HTTP header in the @response object
    # assert_redirected_to user_path(assigns(:user))
  end

  test "should show user" do
    get :show, :id => @user1.to_param
    assert_response :success
  end
  
  test "should show user audit" do
    get :show, :id => @user1.to_param, :audit_id => @user1.audits.first.to_param
    assert_response :success
  end
  
  test "should get edit" do
    get :edit, :id => @user1.to_param
    assert_response :success
  end

  test "should not be allowed to edit if somebody else is editing" do
    @user1.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    get :edit, :id => @user1.to_param
    assert assigns(:not_editable)
  end

  test "should not be allowed to update if somebody else is editing" do
    @user1.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    put :update, :id => @user1.to_param, :user => {}
    assert assigns(:not_editable)
  end

  test "should update user" do
    put :update, :id => @user1.to_param, :user => {}
    assert flash[:info]
    
    assert_redirected_to user_path(assigns(:user))
  end

  test "should destroy user" do
    delete :destroy, :id => @user1.to_param
    assert_not_nil @user1.reload().deleted_at 
  end
end