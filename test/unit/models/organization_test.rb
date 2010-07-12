require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  def setup
    @organization = Organization.make
  end
  
  test "truth" do
    assert true
  end
end