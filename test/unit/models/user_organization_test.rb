require 'test_helper'

class UserOrganizationTest < ActiveSupport::TestCase
  def setup
    @user_org = UserOrganization.make
  end
  
  test "truth" do
    assert true
  end
end