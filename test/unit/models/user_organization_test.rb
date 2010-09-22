require 'test_helper'

class UserOrganizationTest < ActiveSupport::TestCase
  def setup
    @user_org = UserOrganization.make
  end
  
  test "should get a validation error creating a user org with the same user_id and organization_id" do
    bad_user_org = UserOrganization.create :user_id => @user_org.user_id, :organization_id => @user_org.organization_id
    assert !bad_user_org.id
    assert bad_user_org.errors
  end

  test "should get a validation error updating an existing user org to be the same user_id and organization_id as a different user org" do
    bad_user_org = UserOrganization.make
    bad_user_org.update_attributes :user_id => @user_org.user_id, :organization_id => @user_org.organization_id
    assert bad_user_org.errors
  end
end