class ActiveRecord::ModelDslWorkflow < ActiveRecord::ModelDsl
  # A custom SQL query to be executed when the export is run
  attr_accessor :sql_query
  # A mapping from symbol to english word for states
  attr_accessor :states_to_english
  # A mapping from symbol to english word for events
  attr_accessor :events_to_english
  # If this is true, the workflow updates will not execute
  attr_accessor :workflow_disabled

  def initialize model_class
    super model_class
    self.states_to_english = HashWithIndifferentAccess.new
    self.events_to_english = HashWithIndifferentAccess.new
  end
  
  def state_to_english state_name
    if !state_name.blank? && states_to_english && states_to_english.is_a?(Hash)
      states_to_english[state_name.to_sym]
    end || state_name
  end
  
  def event_to_english event_name
    if !event_name.blank? && events_to_english && events_to_english.is_a?(Hash)
      events_to_english[event_name.to_sym]
    end || event_name
  end
  
  def add_state_to_english new_state, state_name
    states_to_english[new_state.to_sym] = state_name
  end

  def add_event_to_english new_event, event_name
    events_to_english[new_event.to_sym] = event_name
  end

  def clear_states_to_english
    states_to_english.clear
  end

  def clear_events_to_english
    events_to_english.clear
  end
  
end