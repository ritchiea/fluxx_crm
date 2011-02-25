require 'test_helper'

class ModelDslWorkflowTest < ActiveSupport::TestCase
  def setup
    @dsl_workflow = ActiveRecord::ModelDslWorkflow.new Race
  end
  
  test 'state and events should both initally be empty' do
    assert @dsl_workflow.states_to_english.empty?
    assert @dsl_workflow.events_to_english.empty?    
  end
  
  test "add state via add_state_to_english" do
    assert_equal Hash.new, @dsl_workflow.states_to_english
    @dsl_workflow.add_state_to_english :a_new_state, 'A New State'
    assert_equal @dsl_workflow.states_to_english[:a_new_state], 'A New State'
  end
  test "add event via add_event_to_english" do
    @dsl_workflow.add_event_to_english :a_new_event, 'A New Event'
    assert_equal @dsl_workflow.events_to_english[:a_new_event], 'A New Event'
  end

  test 'clearing states' do
    @dsl_workflow.add_state_to_english :a_new_state, 'A New State'
    assert !@dsl_workflow.states_to_english.empty?
    @dsl_workflow.clear_states_to_english
    assert @dsl_workflow.states_to_english.empty?
  end
  
  test 'clearing events' do
    @dsl_workflow.add_event_to_english :a_new_event, 'A New Event'
    assert !@dsl_workflow.events_to_english.empty?
    @dsl_workflow.clear_events_to_english
    assert @dsl_workflow.events_to_english.empty?
  end
  
  test 'clearing and adding' do
    race = Race.new
    workflow = race.workflow_object
    assert_equal workflow.states_to_english.size, 4
    workflow.clear_states_to_english
    assert workflow.states_to_english.empty?
    workflow.add_state_to_english :a_new_state, 'A New State'
    assert_equal workflow.states_to_english.size, 1
    race.state = 'a_new_state'
    assert_equal workflow.state_to_english(race), 'A New State'
  end
  
  test 'category test new' do
    states = Race.all_states_with_category 'new'
    assert_equal [:new], states
  end
  
  test 'category test fun' do
    states = Race.all_states_with_category 'fun'
    assert_equal [:beginning], states
  end

end