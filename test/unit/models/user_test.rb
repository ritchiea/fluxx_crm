require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.make
  end
  
  test "truth" do
    assert true
  end
end