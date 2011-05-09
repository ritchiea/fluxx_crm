require 'test_helper'

class AlertTest < ActiveSupport::TestCase
  def setup
    RealtimeUpdate.delete_all
  end

  def alert_is_triggered
    alert_is_triggered = false
    Alert.with_triggered_alerts!{|triggered_alert, matching_rtus| alert_is_triggered = true }
    alert_is_triggered
  end

  test "no alert is triggered if we don't have any alert" do
    assert_equal 0, Alert.count
    assert !alert_is_triggered
  end

  test "no alert is triggered if there are no rtus" do
    Alert.make
    assert !alert_is_triggered
  end

  test "no alert is triggered if the rtus have already been processed" do
    rtu = RealtimeUpdate.make
    Alert.make(:last_realtime_update_id => rtu.id)
    assert !alert_is_triggered
  end

  test "alert is triggered if its filters match the rtu and the rtu hasn't been processed" do
    user = User.make(:email => 'forfiter@szwagier.pl')
    rtu = RealtimeUpdate.make(:model_class => User, :model_id => user.id)
    Alert.make(:last_realtime_update_id => rtu.id - 1, :filter => RTUMatcher::Attribute.new(:attribute => :email, :value => 'forfiter@szwagier.pl'))
    assert alert_is_triggered
  end

  test "alert is not triggered if its filters do not match the rtu for a non processed rtu" do
    user = User.make(:email => 'forfiter@szwagier.pl')
    rtu = RealtimeUpdate.make(:model_class => User, :model_id => user.id)
    Alert.make(:last_realtime_update_id => rtu.id - 1, :filter => RTUMatcher::Attribute.new(:attribute => :email, :value => 'forfiter@franca.pl'))
    assert alert_is_triggered
  end
end
