require 'test_helper'

class AlertTransitionStateTest < ActiveSupport::TestCase
  def setup
    @alert_transition_state = AlertTransitionState.make
  end
  
  test "truth" do
    assert true
  end
end