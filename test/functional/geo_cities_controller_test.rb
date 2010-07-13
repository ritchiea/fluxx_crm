require 'test_helper'

class GeoCitiesControllerTest < ActionController::TestCase

  def setup
    @user1 = User.make
    login_as @user1
  end
  
  test "assert truth" do
    assert true
  end
end
