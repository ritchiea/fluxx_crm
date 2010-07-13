require 'test_helper'

class OrganizationsControllerTest < ActionController::TestCase

  def setup
    @user1 = User.make
    login_as @user1
    @org1 = Organization.make
    @org2 = Organization.make
    @org3 = Organization.make(:parent_org => @org2)
    @org4 = Organization.make(:parent_org => @org2)
    @user_org = UserOrganization.make(:user => @user1, :organization => @org4)
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:organizations)
  end
  
  test "should get CSV index" do
    get :index, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:organizations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create organization" do
    assert_difference('Organization.count') do
      post :create, :organization => { :name => 'some random name for you' }
    end

    # Figure out how to determine a 201 and the options therein; some HTTP header in the @response object
    # assert_redirected_to organization_path(assigns(:organization))
  end

  test "should show organization" do
    get :show, :id => @org1.to_param
    assert_response :success
  end
  
  test "should show organization audit" do
    get :show, :id => @org1.to_param, :audit_id => @org1.audits.first.to_param
    assert_response :success
  end
  
  # TODO ESH: fix; currently show organizations doesn't do too much
  # test "should show organization with satellites" do
  #   get :show, :id => @org2.to_param
  #   assert @response.body.index @org3.id.to_s
  #   assert @response.body.index @org4.id.to_s
  #   assert_response :success
  # end
  
  test "should get edit" do
    get :edit, :id => @org1.to_param
    assert_response :success
  end

  test "should not be allowed to edit if somebody else is editing" do
    @org1.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    get :edit, :id => @org1.to_param
    assert assigns(:not_editable)
  end

  test "should not be allowed to update if somebody else is editing" do
    @org1.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    put :update, :id => @org1.to_param, :organization => {}
    assert assigns(:not_editable)
  end

  test "should update organization" do
    put :update, :id => @org1.to_param, :organization => {}
    assert flash[:info]
    
    assert_redirected_to organization_path(assigns(:organization))
  end

  test "should destroy organization" do
    delete :destroy, :id => @org1.to_param
    assert_not_nil @org1.reload().deleted_at 
  end
  
  test "should confirm that name_exists" do
    get :index, :name => @org1.name, :format => :json
    a = @response.body.de_json # try to deserialize the JSON to an array
    assert_equal @org1.id, a.first['value']
  end
  
  test "autocomplete" do
    @user_org.destroy
    Organization.delete_all 'parent_org_id is not null'
    Organization.delete_all
    @org1 = Organization.make
    
    get :index, :organization => {:name => @org1.name}, :format => :json
    a = @response.body.de_json # try to deserialize the JSON to an array
    assert_equal @org1.name, a.first['label']
    assert_equal @org1.id, a.first['value']
  end

  # TODO ESH: add a way in insta's rest interface to merge dupes
  # test "Check that we can merge two orgs" do
  #   login_as_user_with_role Role.data_cleanup_role_name, User
  #   good_org = Organization.make
  #   dupe_org = Organization.make
  #   put :merge_dupes, :base => good_org.id, :ids => "#{good_org.id}, #{dupe_org.id}"
  #   assert !(Organization.exists? dupe_org.id)
  # end
  # 
  # test "Check that we can merge two HQ orgs that have satellites" do
  #   login_as_user_with_role Role.data_cleanup_role_name, User
  #   good_org = Organization.make
  #   good_org_sat = Organization.make :parent_org => good_org
  #   dupe_org = Organization.make
  #   dupe_org_sat = Organization.make :parent_org => dupe_org
  #   good_user = User.make
  #   dupe_user = User.make
  #   good_user_org = UserOrganization.make :user => good_user, :organization => good_org
  #   dupe_user_org = UserOrganization.make :user => dupe_user, :organization => dupe_org
  #   put :merge_dupes, :base => good_org.id, :ids => "#{good_org.id}, #{dupe_org.id}"
  #   assert !(Organization.exists? dupe_org.id)
  #   assert_equal 2, good_org.user_organizations.size
  #   assert_equal 2, good_org.has_satellites?
  # end
  # 
  # test "Should not be able to merge a HQ with satellites to a satellite" do
  #   login_as_user_with_role Role.data_cleanup_role_name, User
  #   good_org = Organization.make
  #   good_org_sat = Organization.make :parent_org => good_org
  #   dupe_org = Organization.make
  #   dupe_org_sat = Organization.make :parent_org => dupe_org
  #   put :merge_dupes, :base => good_org_sat.id, :ids => "#{good_org_sat.id}, #{dupe_org.id}"
  #   assert Organization.exists? dupe_org.id
  #   assert_equal 1, good_org.reload.has_satellites?
  #   assert_equal 1, dupe_org.reload.has_satellites?
  # end
  # 
  # test "Should not be able to link a satellite to its hq" do
  #   login_as_user_with_role Role.data_cleanup_role_name, User
  #   good_org = Organization.make
  #   sat_to_be = Organization.make
  #   put :link_satellites, :base => good_org.id, :ids => "#{good_org.id}, #{sat_to_be.id}"
  #   assert Organization.exists?(sat_to_be.id)
  #   assert_equal 1, good_org.reload.has_satellites?
  #   assert !sat_to_be.reload.has_satellites?
  # end
  
  
end
