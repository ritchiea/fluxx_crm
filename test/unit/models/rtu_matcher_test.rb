require 'test_helper'

class RTUMatcherTest < ActiveSupport::TestCase
  def assert_jsons_are_equal(json1, json2)
    hash1 = ActiveSupport::JSON.decode(json1)
    hash2 = ActiveSupport::JSON.decode(json2)
    assert_equal hash1, hash2
  end

################## Equality matching ####################

  test "successful match of an attribute for equality" do
    user = User.make(:email => 'foo@bar.com')
    rtu = RealtimeUpdate.make(:model_class => User, :model_id => user.id)
    matcher = RTUMatcher::Attribute.new(:attribute => :email, :value => 'foo@bar.com')
    assert matcher.matches?(rtu)
  end

  test "unsuccessful match of an attribute for equality" do
    user = User.make(:email => 'foo@bar.com')
    rtu = RealtimeUpdate.make(:model_class => User, :model_id => user.id)
    matcher = RTUMatcher::Attribute.new(:attribute => :email, :value => 'bar@foo.com')
    assert !matcher.matches?(rtu)
  end

################ Number matching ################

  test "successful match of an attribute being greater than an integer" do
    user = User.make(:email => 'foo@bar.com')
    rtu = RealtimeUpdate.make(:model_class => User, :model_id => user.id)
    matcher = RTUMatcher::Attribute.new(:attribute => :id, :comparer => '>', :value => user.id - 1)
    assert matcher.matches?(rtu)
  end

  test "unsuccessful match of an attribute being greater than an integer" do
    user = User.make(:email => 'foo@bar.com')
    rtu = RealtimeUpdate.make(:model_class => User, :model_id => user.id)
    matcher = RTUMatcher::Attribute.new(:attribute => :id, :comparer => '>', :value => user.id)
    assert !matcher.matches?(rtu)
  end

################### Due and overdue filters #####################

  test "successful match a due_in days matcher for the exact date" do
    work_task = WorkTask.make(:due_at => 2.days.from_now)
    rtu = RealtimeUpdate.make(:model_class => WorkTask, :model_id => work_task.id)
    matcher = RTUMatcher::Attribute.new(:attribute => :due_at, :comparer => 'due_in', :value => 2.days)
    assert matcher.matches?(rtu)
  end

  test "successful match a due_in days matcher" do
    work_task = WorkTask.make(:due_at => 1.days.from_now)
    rtu = RealtimeUpdate.make(:model_class => WorkTask, :model_id => work_task.id)
    matcher = RTUMatcher::Attribute.new(:attribute => :due_at, :comparer => 'due_in', :value => 2.days)
    assert matcher.matches?(rtu)
  end

  test "unsuccessful match a due_in days matcher" do
    work_task = WorkTask.make(:due_at => 3.days.from_now)
    rtu = RealtimeUpdate.make(:model_class => WorkTask, :model_id => work_task.id)
    matcher = RTUMatcher::Attribute.new(:attribute => :due_at, :comparer => 'due_in', :value => 2.days)
    assert !matcher.matches?(rtu)
  end

  test "successful match an overdue_by days matcher for the exact date" do
    work_task = WorkTask.make(:due_at => 2.days.ago)
    rtu = RealtimeUpdate.make(:model_class => WorkTask, :model_id => work_task.id)
    matcher = RTUMatcher::Attribute.new(:attribute => :due_at, :comparer => 'overdue_by', :value => 2.days)
    assert matcher.matches?(rtu)
  end

  test "successful match an overdue_by days matcher" do
    work_task = WorkTask.make(:due_at => 3.days.ago)
    rtu = RealtimeUpdate.make(:model_class => WorkTask, :model_id => work_task.id)
    matcher = RTUMatcher::Attribute.new(:attribute => :due_at, :comparer => 'overdue_by', :value => 2.days)
    assert matcher.matches?(rtu)
  end

  test "unsuccessful match an overdue_by days matcher" do
    work_task = WorkTask.make(:due_at => 1.days.ago)
    rtu = RealtimeUpdate.make(:model_class => WorkTask, :model_id => work_task.id)
    matcher = RTUMatcher::Attribute.new(:attribute => :due_at, :comparer => 'overdue_by', :value => 2.days)
    assert !matcher.matches?(rtu)
  end

################## Serialization of single matchers #####################

  test "serialization" do
    matcher = RTUMatcher::Attribute.new(:attribute => :email, :value => 'bar@foo.com')
    assert_jsons_are_equal '{"class":"RTUMatcher::Attribute", "attributes": {"value":"bar@foo.com", "comparer":"==", "attribute":"email"}}', matcher.to_json
  end

  test "deserialization" do
    user = User.make(:email => 'foo@bar.com')
    rtu = RealtimeUpdate.make(:model_class => User, :model_id => user.id)
    matcher = RTUMatcher.from_json('{"class":"RTUMatcher::Attribute", "attributes": {"value":"foo@bar.com", "comparer":"==", "attribute":"email"}}')
    assert matcher.matches?(rtu)
  end

############# Composed matchers ##############

  test "successful match of 3 matchers" do
    user = User.make(:email => 'foo@bar.com', :state => 'a state', :test_user_flag => true)
    rtu = RealtimeUpdate.make(:model_class => User, :model_id => user.id)
    matcher = RTUMatcher::Attribute.new(:attribute => :email, :value => 'foo@bar.com') &
              RTUMatcher::Attribute.new(:attribute => :state, :value => 'a state') &
              RTUMatcher::Attribute.new(:attribute => :test_user_flag, :value => true)
    assert matcher.matches?(rtu)
  end

  test "unsuccessful match of 3 matchers" do
    user = User.make(:email => 'foo@bar.com', :state => 'a state', :test_user_flag => false)
    rtu = RealtimeUpdate.make(:model_class => User, :model_id => user.id)
    matcher = RTUMatcher::Attribute.new(:attribute => :email, :value => 'foo@bar.com') &
              RTUMatcher::Attribute.new(:attribute => :state, :value => 'a state') &
              RTUMatcher::Attribute.new(:attribute => :test_user_flag, :value => true)
    assert !matcher.matches?(rtu)
  end

  test "successful match a combination of ands and ors matchers" do
    user = User.make(:email => 'foo@bar.com', :state => 'a state', :test_user_flag => false)
    rtu = RealtimeUpdate.make(:model_class => User, :model_id => user.id)
    matcher = RTUMatcher::Attribute.new(:attribute => :email, :value => 'foo@bar.com') &
              RTUMatcher::Attribute.new(:attribute => :state, :value => 'a state') |
              RTUMatcher::Attribute.new(:attribute => :test_user_flag, :value => true)
    assert matcher.matches?(rtu)
  end

  test "negating a successful match should result in an unsuccessful match" do
    user = User.make(:email => 'foo@bar.com', :state => 'a state', :test_user_flag => false)
    rtu = RealtimeUpdate.make(:model_class => User, :model_id => user.id)
    matcher = (RTUMatcher::Attribute.new(:attribute => :email, :value => 'foo@bar.com') &
              RTUMatcher::Attribute.new(:attribute => :state, :value => 'a state') |
              RTUMatcher::Attribute.new(:attribute => :test_user_flag, :value => true)).not
    assert !matcher.matches?(rtu)
  end

  test "serialization of a composed matcher" do
    matcher = RTUMatcher::Attribute.new(:attribute => :email, :value => 'foo@bar.com') &
              RTUMatcher::Attribute.new(:attribute => :state, :value => 'a state') &
              RTUMatcher::Attribute.new(:attribute => :test_user_flag, :value => true)
    assert_jsons_are_equal '{"and":[{"class":"RTUMatcher::Attribute", "attributes":{"value":"foo@bar.com", "comparer":"==", "attribute":"email"}}, {"class":"RTUMatcher::Attribute", "attributes":{"value":"a state", "comparer":"==", "attribute":"state"}}, {"class":"RTUMatcher::Attribute", "attributes":{"value":true, "comparer":"==", "attribute":"test_user_flag"}}]}', matcher.to_json
  end

  test "deserialization of a composed matcher" do
    user = User.make(:email => 'foo@bar.com', :state => 'a state', :test_user_flag => true)
    rtu = RealtimeUpdate.make(:model_class => User, :model_id => user.id)
    matcher = RTUMatcher.from_json('{"and": [{"and": [{"class":"RTUMatcher::Attribute", "attributes": {"value":"foo@bar.com", "comparer":"==", "attribute":"email"}}, {"class":"RTUMatcher::Attribute", "attributes": {"value":"a state", "comparer":"==", "attribute":"state"}}]}, {"class":"RTUMatcher::Attribute", "attributes": {"comparer":"==", "value":true, "attribute":"test_user_flag"}}]}')
    assert matcher.matches?(rtu)
  end
end

