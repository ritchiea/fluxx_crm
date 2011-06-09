require 'test_helper'

class MultiElementValuesControllerTest < ActionController::TestCase

  def setup
    @user1 = User.make
    login_as @user1
    @multi_element_value = MultiElementValue.make
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:multi_element_values)
  end
  
  test "should get CSV index" do
    get :index, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:multi_element_values)
  end
  
  test "autocomplete" do
    lookup_instance = MultiElementValue.make
    get :index, :name => lookup_instance.name, :format => :autocomplete
    a = @response.body.de_json # try to deserialize the JSON to an array
    assert a.map{|elem| elem['value']}.include?(lookup_instance.id)
  end

  test "should confirm that name_exists" do
    get :index, :name => @multi_element_value.name, :format => :autocomplete
    a = @response.body.de_json # try to deserialize the JSON to an array
    assert a.map{|elem| elem['value']}.include?(@multi_element_value.id)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create multi_element_value" do
    assert_difference('MultiElementValue.count') do
      post :create, :multi_element_value => { :name => 'some random name for you' }
    end

    assert 201, @response.status
    assert @response.header["Location"] =~ /#{multi_element_value_path(assigns(:multi_element_value))}$/
  end

  test "should show multi_element_value" do
    get :show, :id => @multi_element_value.to_param
    assert_response :success
  end

  test "should show multi_element_value with documents" do
    model_doc1 = ModelDocument.make(:documentable => @multi_element_value)
    model_doc2 = ModelDocument.make(:documentable => @multi_element_value)
    get :show, :id => @multi_element_value.to_param
    assert_response :success
  end
  
  test "should show multi_element_value with groups" do
    group = Group.make
    group_member1 = GroupMember.make :groupable => @multi_element_value, :group => group
    group_member2 = GroupMember.make :groupable => @multi_element_value, :group => group
    get :show, :id => @multi_element_value.to_param
    assert_response :success
  end
  
  test "should show multi_element_value with audits" do
    Audit.make :auditable_id => @multi_element_value.to_param, :auditable_type => @multi_element_value.class.name
    get :show, :id => @multi_element_value.to_param
    assert_response :success
  end
  
  test "should show multi_element_value audit" do
    get :show, :id => @multi_element_value.to_param, :audit_id => @multi_element_value.audits.first.to_param
    assert_response :success
  end
  
  test "should get edit" do
    get :edit, :id => @multi_element_value.to_param
    assert_response :success
  end

  test "should not be allowed to edit if somebody else is editing" do
    @multi_element_value.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    get :edit, :id => @multi_element_value.to_param
    assert assigns(:not_editable)
  end

  test "should not be allowed to update if somebody else is editing" do
    @multi_element_value.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    put :update, :id => @multi_element_value.to_param, :multi_element_value => {}
    assert assigns(:not_editable)
  end

  test "should update multi_element_value" do
    put :update, :id => @multi_element_value.to_param, :multi_element_value => {}
    assert flash[:info]
    
    assert 201, @response.status
    assert @response.header["Location"] =~ /#{multi_element_value_path(assigns(:multi_element_value))}$/
  end

  test "should destroy multi_element_value" do
    delete :destroy, :id => @multi_element_value.to_param
    assert_not_nil @multi_element_value.reload().deleted_at 
  end
end
