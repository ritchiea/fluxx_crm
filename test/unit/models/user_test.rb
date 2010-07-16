require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.make
  end
  
  test "test that a role can be assigned and deleted" do
    new_user = User.make
    new_user.add_role 'fred_role'
    assert_equal 'fred_role', new_user.roles.first
    new_user.reload.has_role? 'fred_role'
    new_user.remove_role 'fred_role'
    assert new_user.roles.empty?
    assert !(new_user.reload.has_role? 'fred_role')
  end
  
  test "test that has_role works with multiple roles" do
    new_user = User.make
    (1..10).each {|i| new_user.add_role "fred_role_#{i}"}
    (1..10).each {|i| new_user.reload.has_role? "fred_role_#{i}"}
  end
  
end