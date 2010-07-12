require 'test_helper'

class GeoCountryTest < ActiveSupport::TestCase
  def setup
    @geo_country = GeoCountry.make
  end
  
  test "truth" do
    assert true
  end
end