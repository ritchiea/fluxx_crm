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

  test "alerts should have a unique name" do
    alert1 = Alert.make
    alert2 = Alert.make_unsaved(:name => alert1.name)
    alert2.valid?
    assert_equal "has already been taken", alert2.errors[:name].first
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

  test "alert should coalesce rtus that point to the same model" do
    Alert.delete_all
    Alert.make
    user1 = User.make
    rtu1 = RealtimeUpdate.make(:type_name => User, :model_class => User, :model_id => user1.id)
    rtu2 = RealtimeUpdate.make(:type_name => User, :model_class => User, :model_id => user1.id)
    rtu3 = RealtimeUpdate.make(:type_name => User, :model_class => User, :model_id => user1.id)
    user2 = User.make
    rtu4 = RealtimeUpdate.make(:type_name => User, :model_class => User, :model_id => user2.id)
    rtu5 = RealtimeUpdate.make(:type_name => User, :model_class => User, :model_id => user2.id)
    rtu6 = RealtimeUpdate.make(:type_name => User, :model_class => User, :model_id => user2.id)

    filtered_rtus = []
    Alert.with_triggered_alerts!(skip_filter = true){|triggered_alert, matching_rtus| filtered_rtus = matching_rtus }
    assert_equal [rtu3, rtu6], filtered_rtus
  end
end
