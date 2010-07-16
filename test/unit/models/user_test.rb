require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
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
  
  test "test that multiple instances of the same user object can update the role object successfully" do
    new_user = User.make
    user_1 = User.find new_user.id
    user_2 = User.find new_user.id
    user_1.add_role 'fred_role_1'
    assert user_1.has_role? 'fred_role_1'
    user_2.add_role 'fred_role_2'
    assert user_2.has_role? 'fred_role_1'
    assert user_2.has_role? 'fred_role_2'
    new_user.reload
    assert new_user.has_role? 'fred_role_1'
    assert new_user.has_role? 'fred_role_2'

    # The user_1 is unaffected because it has not been reloaded
    assert !(user_1.has_role? 'fred_role_2')
  end
  
  test "Check that we can merge two users" do
    good_user = User.make
    dupe_user = User.make
    good_user.merge dupe_user
    assert !(User.exists? dupe_user.id)
  end

  test "Check that we can merge two users that created or modified notes" do
    good_user = User.make
    dupe_user = User.make
    note = Note.make :created_by => good_user, :updated_by => good_user
    assert_equal note.created_by_id, good_user.id
    assert_equal note.updated_by_id, good_user.id
    dup_note = Note.make :created_by => dupe_user, :updated_by => dupe_user
    assert_equal dup_note.created_by_id, dupe_user.id
    assert_equal dup_note.updated_by_id, dupe_user.id

    good_user.merge dupe_user
    assert !(User.exists? dupe_user.id)
    assert_equal 0, Note.count(:conditions => ['created_by_id = ?', dupe_user.id])
    assert_equal 2, Note.count(:conditions => ['created_by_id = ?', good_user.id])
  end

  test "Check that we can merge two users that have notes created about them" do
    good_user = User.make
    dupe_user = User.make
    note = Note.make :notable_type => User.name, :notable => good_user
    assert_equal note.notable_id, good_user.id
    dupe_note = Note.make :notable_type => User.name, :notable => dupe_user
    assert_equal dupe_note.notable_id, dupe_user.id

    good_user.merge dupe_user
    assert !(User.exists? dupe_user.id)
    assert_equal 0, Note.count(:conditions => ['notable_type = ? AND notable_id = ?', User.name, dupe_user.id])
    assert_equal 2, Note.count(:conditions => ['notable_type = ? AND notable_id = ?', User.name, good_user.id])
  end

  test "Check that we can merge two users where the dupe user has locked an org" do
    good_user = User.make
    dupe_user = User.make
    org = Organization.make :locked_by => dupe_user
    assert_equal org.locked_by_id, dupe_user.id

    good_user.merge dupe_user
    assert !(User.exists? dupe_user.id)
    assert_equal 0, Organization.count(:conditions => ['locked_by_id = ?', dupe_user.id])
  end
  
  test "Check that we can merge two users that have assigned the same role" do
    good_user = User.make
    good_user.add_role 'role_good'
    dupe_user = User.make
    dupe_user.add_role 'role_dupe'
    good_user.merge dupe_user
    assert !(User.exists? dupe_user.id)
    assert good_user.has_role? 'role_dupe'
  end
  
  test "Check that we can merge two users that each are members of a particular group" do
    good_user_group = Group.make
    dupe_user_group = Group.make
    good_user = User.make
    dupe_user = User.make
    GroupMember.make :groupable => good_user, :groupable_type => User.name, :group => good_user_group
    GroupMember.make :groupable => dupe_user, :groupable_type => User.name, :group => dupe_user_group
    good_user.merge dupe_user
    assert !(User.exists? dupe_user.id)
    assert good_user.groups.include?(good_user_group)
    assert good_user.groups.include?(dupe_user_group)
  end
  
  
  test "Check that we can merge two users that have overlapping user orgs" do
    good_user = User.make
    dupe_user = User.make
    org = Organization.make
    good_user_org = UserOrganization.make :user => good_user, :organization => org
    dupe_user_org = UserOrganization.make :user => dupe_user, :organization => org
    assert good_user.merge dupe_user
    assert !(User.exists? dupe_user.id)
    assert !(UserOrganization.exists? dupe_user_org.id)
    assert UserOrganization.exists? good_user_org.id
  end
  
end