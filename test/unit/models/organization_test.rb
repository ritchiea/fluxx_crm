require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  def setup
    @organization = Organization.make
  end
  
  test "Organization validation" do
    org = Organization.create
    assert_equal 2, org.errors.size
    org = Organization.make :name => 'freddie mac'
    assert_not_nil org.id
  end
  
  test "Adding organizations to users" do
    u = User.make :first_name => 'Eric', :login => 'ericfluxx', :email => 'fred@acesfconsulting.com'
    org = Organization.make :name => 'freddie mac'
    assert_equal 0, u.organizations.size
    assert_equal 0, org.users.size
    u.organizations << org
    assert_equal 1, u.organizations.size
    assert_equal 1, org.reload().users.size
  end

  test "Setting up hq/satellite organizations" do
    hq_org = Organization.make :name => 'freddie mac'
  end

  test "merge remove duplicated organization" do
    # build organizations
    org1 = Organization.make
    org1_duplicate = Organization.make(:name => org1.name)
    # Merge
    assert org1.merge(org1_duplicate)
    # Check duplicates doesnt exists anymore
    assert_nil Organization.find_by_id(org1_duplicate.id)
  end

  test "merge move users to point at representant" do
    # build organizations
    org1, org2, org3 = Organization.make, Organization.make, Organization.make
    org1_duplicate = Organization.make(:name => org1.name)
    # build users
    u1 = User.make :first_name => 'Marcelo', :login => 'marklazz', :email => 'marklazz.uy@gmail.com'
    u2 = User.make :first_name => 'Eric', :login => 'ericfluxx', :email => 'fred@acesfconsulting.com'
    u3 = User.make :first_name => 'Michael', :login => 'michaelfluxx', :email => 'michael@acesfconsulting.com'
    # set associations between orgs and users
    u1.organizations << org1
    u1.update_attribute(:primary_user_organization_id, u1.user_organizations.first.id)
    u1.organizations << org2
    u2.organizations << org1_duplicate
    u2.update_attribute(:primary_user_organization_id, u2.user_organizations.first.id)
    u2.organizations << org3
    u3.organizations << org3
    u3.organizations << org1_duplicate
    u3.update_attribute(:primary_user_organization_id, u3.user_organizations.first.id)
    # Merge
    assert org1.merge(org1_duplicate)
    # reload user models
    u1.reload
    u2.reload
    u3.reload
    # Validate successfull transition of users to the organization representant
    assert u2.organizations.include?(org1)
    assert u3.organizations.include?(org1)
    # check existing associations did not changed
    assert u1.organizations.include?(org1)
    assert u1.organizations.include?(org2)
    assert u2.organizations.include?(org3)
    assert u3.organizations.include?(org3)
    # also check that primary_organization changed
    assert_equal UserOrganization.find(u2.primary_user_organization_id).organization_id, org1.id
    # but for the case of primary is not merged, then it shouldn't change
    assert_equal UserOrganization.find(u3.primary_user_organization_id).organization_id, org3.id
  end

end