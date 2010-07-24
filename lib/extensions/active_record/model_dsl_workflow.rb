class ActiveRecord::ModelDslWorkflow < ActiveRecord::ModelDsl
  # A custom SQL query to be executed when the export is run
  attr_accessor :sql_query
  # A mapping from symbol to english word for states
  attr_accessor :states_to_english
  # A mapping from symbol to english word for events
  attr_accessor :events_to_english
  
  def state_to_english state_name
    if state_to_english && state_to_english.is_a?(Hash)
      state_to_english[state_name.to_sym]
    end || state_name
  end
  
  def event_to_english event_name
    if event_to_english && event_to_english.is_a?(Hash)
      event_to_english[event_name.to_sym]
    end || event_name
  end
end