require 'test_helper'

class AlertTest < ActiveSupport::TestCase
  def alert_is_triggered_for_work_task(work_task_opts)
    work_task = WorkTask.make(work_task_opts)
    rtu = RealtimeUpdate.make(:type_name => WorkTask.name, :model_id => work_task.id)

    alert_is_triggered
  end

  def alert_is_triggered
    is_triggered = false
    Alert.with_triggered_alerts!{|triggered_alert, matching_rtus| is_triggered = true }
    is_triggered
  end

  def create_work_task_alert(alert_filter)
    alert_filter_as_json = alert_filter.inject([]) do |array, (k,v)|
      array << {"name" => "work_task[#{k}][]", "value" => v}
      array
    end.to_json

    Alert.create!(:name => "an alert", :filter => alert_filter_as_json, :model_controller_type => 'WorkTasksController')
  end

  def setup
    RealtimeUpdate.delete_all
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
    Alert.make :model_controller_type => 'UsersController'
    user1 = User.make
    rtu1 = RealtimeUpdate.make(:type_name => User.name, :model_class => User.name, :model_id => user1.id)
    rtu2 = RealtimeUpdate.make(:type_name => User.name, :model_class => User.name, :model_id => user1.id)
    rtu3 = RealtimeUpdate.make(:type_name => User.name, :model_class => User.name, :model_id => user1.id)
    user2 = User.make
    rtu4 = RealtimeUpdate.make(:type_name => User.name, :model_class => User.name, :model_id => user2.id)
    rtu5 = RealtimeUpdate.make(:type_name => User.name, :model_class => User.name, :model_id => user2.id)
    rtu6 = RealtimeUpdate.make(:type_name => User.name, :model_class => User.name, :model_id => user2.id)

    filtered_models = []

    Alert.any_instance.stubs(:should_be_triggered_by_model?).returns(true)
    Alert.any_instance.stubs(:has_rtu_based_filtered_attrs?).returns(true)
    Alert.any_instance.stubs(:model_controller_type?).returns('UsersController')
    Alert.with_triggered_alerts!{|triggered_alert, matching_models| filtered_models = matching_models }
    p "ESH: filtered_models = #{filtered_models.inspect}"
    p "ESH: [user1, user2] = #{[user1, user2].inspect}"
    assert_equal [user1, user2].sort_by(&:id), filtered_models.sort_by(&:id)
  end

  test "alert is triggered if the overdue matcher matches the rtu" do
    create_work_task_alert(:name => "the name", :overdue_by_days => "8")
    assert alert_is_triggered_for_work_task(:name => "the name", :due_at => 10.days.ago)
  end

  test "alert is not triggered if the overdue_by_days matcher does not match the rtu" do
    create_work_task_alert(:name => "the name", :overdue_by_days => "11")
    assert !alert_is_triggered_for_work_task(:name => "the name", :due_at => 10.days.ago)
  end

  test "alert is not triggered if the equality matcher does not match the name" do
    create_work_task_alert(:name => "some name", :overdue_by_days => "8")
    assert !alert_is_triggered_for_work_task(:name => "the name", :due_at => 10.days.ago)
  end

  test "alert is triggered if the due_in_days matcher matches the rtu" do
    create_work_task_alert(:name => "the name", :due_in_days => "8")
    assert alert_is_triggered_for_work_task(:name => "the name", :due_at => 7.days.from_now)
  end

  test "alert is not triggered if the due_in_days matcher does not match the rtu" do
    # TODO ESH: fix by adding due_in_days similar to due_within_days derived filter in fluxx_request_report
    alert = create_work_task_alert(:name => "the name", :due_in_days => "11")
    assert !alert_is_triggered_for_work_task(:name => "the name", :due_at => 14.days.from_now)
  end

  test "rtus are not used to match overdue_by_days matchers" do
    create_work_task_alert(:overdue_by_days => "8")
    WorkTask.make(:due_at => 10.days.ago)
    RealtimeUpdate.delete_all

    assert alert_is_triggered
  end

  test "rtus are not used to match due_at matchers" do
    create_work_task_alert(:due_in_days => 8)
    WorkTask.make(:due_at => 7.days.from_now)
    RealtimeUpdate.delete_all

    assert alert_is_triggered
  end

  test "bla" do
    a = '[{"name":"work_task[report_type][]","value":"InterimBudget"},{"name":"work_task[hierarchies][]","value":"allocation_hierarchy"}]'
  end

  test "make sure resolve_for_dashboard does not create new alerts if the emailNotifications boolean is set to false" do
    assert_difference('Alert.count', 0) do
      dashboard = ClientStore.make :client_store_type => 'Dashboard', :name => 'testing', :data => dashboard_data.gsub(/"emailNotifications":true/, '"emailNotifications":false')
    end
  end

  
  test "make sure resolve_for_dashboard creates new alerts and setting the flag to false deletes it" do
    dashboard = nil
    assert_difference('Alert.count') do
      dashboard = ClientStore.make :client_store_type => 'Dashboard', :name => 'testing', :data => dashboard_data
    end
    alert = Alert.last
    assert_equal dashboard.id, alert.dashboard_id
    assert_equal 4, alert.dashboard_card_id
    
    # Now turn off emailNotifications for all cards in this dashboard
    dashboard.data = dashboard_data.gsub(/"emailNotifications":true/, '"emailNotifications":false')
    resp = dashboard.save
    assert_equal 0, Alert.count
  end

  test "make sure resolve_for_dashboard updates existing alerts" do
    dashboard = ClientStore.make :client_store_type => 'Dashboard', :name => 'testing', :data => dashboard_data
    alert = Alert.last
    assert_equal dashboard.id, alert.dashboard_id
    dashboard.data = dashboard_data.gsub(/"url":"\/organizations"/, '"url":"/users"')
    resp = dashboard.save
    alert = Alert.last
    assert_equal 'UsersController', alert.model_controller_type
  end

  def dashboard_data
   '{"nextUid":8,"cards":[{"uid":4,"title":"Organizations","listing":{"url":"/organizations","data":{}},"detail":{},"settings":{"minimized":false,"locked":false,"emailNotifications":true}},{"uid":7,"title":"People","listing":{"url":"/users?page=5&user[sort_attribute]=full_name&user[sort_order]=asc&utf8=%E2%9C%93","data":{}},"detail":{"url":"/users/10686","data":{}},"settings":{"minimized":false,"locked":false,"emailNotifications":false}}]}'
  end
end
