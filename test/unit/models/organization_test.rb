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
  
  test "make sure that updating the name of an org updates its satellites if any" do
    sat = Organization.make :parent_org_id => @organization.id
    @organization.name = @organization.name + 'fred'
    @organization.save
    assert_equal @organization.name, sat.reload.name
  end
  
  test "Adding organizations to users" do
    u = User.make :first_name => 'Eric', :login => random_login, :email => random_email
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
  
  test "TEst looking up the hq parent" do
    assert_equal @organization, @organization.find_parent_or_self
    sub_org = Organization.make :parent_org_id => @organization.id
    sub_sub_org = Organization.make :parent_org_id => sub_org.id
    assert_equal @organization, sub_sub_org.find_parent_or_self
    
  end
  test "address_for_geocoding removes empty and nil strings" do
    @organization.street_address = 'street_address'
    @organization.city = '  '
    @organization.postal_code = nil
    assert_equal @organization.address_for_geocoding, "street_address"
  end
  test "address_for_geocoding does not include street_address2" do
    @organization.street_address = 'street_address'
    @organization.street_address2 = 'street_address2'
    assert !@organization.address_for_geocoding.include?(@organization.street_address2)
  end

  test "not geocodable if we dont have postal code or city and state" do
    @organization.state = nil
    @organization.postal_code = nil
    assert !@organization.geocodable?
  end

  test "geocodable if we have city and state" do
    @organization.city = "Kailua"
    @organization.geo_state = GeoState.make(:name => 'Hawaii')
    assert @organization.geocodable?
    @organization.save!
  end
  
  test "geocodable if we have postal code" do
    @organization.postal_code = '96734'
    assert @organization.geocodable?
  end
  
  test "wont block save if geocoding quota is hit" do
    Geocoder::Lookup::Google.any_instance.stubs(:fetch_raw_data).returns(Geocoder::GOOGLE_OVER_QUERY_LIMIT)
    @organization.postal_code = '96734'
    assert_nothing_raised do
      @organization.save!
    end
  end

  test "geocoding sets latitude and longitude post validation" do
    @organization.postal_code = '96734' # to force changed with blueprint
    assert_nil @organization.latitude
    assert_nil @organization.longitude
    @organization.valid?
    assert_not_nil @organization.latitude
    assert_not_nil @organization.longitude
  end
  test "geocoding sets state and country post validation" do
    @organization.postal_code = '96734' # to force changed with blueprint
    assert_nil @organization.state_str
    assert_nil @organization.state_code
    assert_nil @organization.country_str
    assert_nil @organization.country_code
    @organization.valid?  # this also grabs data from the geocoder stub, which we check against below
    assert_equal "California", @organization.state_str
    assert_equal "CA", @organization.state_code
    assert_equal "United States", @organization.country_str
    assert_equal "US", @organization.country_code
  end

  test "state_name with state_str and geo_state" do
    @organization.geo_state = nil
    @organization.state_str = nil
    assert_nil @organization.state_name
    @organization.state_str = "foo"
    assert_equal  "foo", @organization.state_name
    geo_state = GeoState.make
    @organization.geo_state = geo_state
    assert_equal  "foo", @organization.state_name
    @organization.state_str = nil
    assert_equal geo_state.name, @organization.state_name
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
    u1 = User.make :first_name => 'Marcelo', :login => random_login, :email => random_email
    u2 = User.make :first_name => 'Eric', :login => random_login, :email => random_email
    u3 = User.make :first_name => 'Michael', :login => random_login, :email => random_email
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
  
  test "switch an org from being a child to being a parent using force_headquarters" do
    org1 = Organization.make
    org2, org3 = Organization.make(:parent_org_id => org1.id), Organization.make(:parent_org_id => org1.id)
    assert_equal org1, org2.parent_org
    assert_equal org1, org3.parent_org
    org3.force_headquarters = '1'
    org3.save
    assert_equal org3, org1.reload.parent_org
    assert_equal org3, org2.reload.parent_org
    assert org3.reload.parent_org.nil?
  end
end