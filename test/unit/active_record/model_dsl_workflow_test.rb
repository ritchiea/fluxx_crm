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
    assert_equal workflow.states_to_english.size, 6
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

  test 'all_events_with_category' do
    assert_equal [:kick_off], Race.all_events_with_category('fun')
  end

  test 'category test fun' do
    states = Race.all_states_with_category 'fun'
    assert_equal [:beginning], states
  end
  
  test 'all_events test' do
    assert_equal [:kick_off, :sprint, :final_sprint, :reject, :send_back_starting_line], Race.all_events
  end

  test 'all_workflow_states' do
    assert_equal [:new, :beginning, :middle, :final], Race.all_workflow_states
  end
  
  test 'all_rejected_states' do
    assert_equal [:rejected], Race.all_rejected_states
  end
  
  test 'all_new_states' do
    assert_equal [:new], Race.all_new_states
  end

  test 'all_sent_back_states' do
    assert_equal [:sent_back_starting_line], Race.all_sent_back_states
  end

  test 'all_events' do
    assert_equal [:kick_off, :sprint, :final_sprint, :reject, :send_back_starting_line], Race.all_events
  end
  
  test 'all_workflow_events' do
    assert_equal [:kick_off, :sprint, :final_sprint], Race.all_workflow_events
  end
  
  test 'all_rejected_events' do
    assert_equal [:reject], Race.all_rejected_events
  end
  
  test 'all_new_events' do
    assert_equal [], Race.all_new_events
  end
  
  test 'all_sent_back_events' do
    assert_equal [:send_back_starting_line], Race.all_sent_back_events
  end
  
  test 'all_state_categories_with_descriptions ' do
    assert_equal [["Funangry", ["fun", "angry"]], ["New", ["new"]]], Race.all_state_categories_with_descriptions 
  end
  
  test 'event_timeline' do
    race = Race.make
    assert_equal(['new', 'beginning', 'middle', 'final'], race.event_timeline)
  end
  
end