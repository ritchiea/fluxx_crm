class ActiveRecord::ModelDslWorkflow < ActiveRecord::ModelDsl
  # A custom SQL query to be executed when the export is run
  attr_accessor :sql_query
  # A mapping from symbol to english word for states
  attr_accessor :states_to_english
  # A mapping from symbol to english word for events
  attr_accessor :events_to_english
  # A list of events to skip validating on when changing state
  attr_accessor :non_validating_events
  # If this is true, the workflow updates will not execute
  attr_accessor :workflow_disabled

  def initialize model_class
    super model_class
    self.states_to_english = HashWithIndifferentAccess.new
    self.events_to_english = HashWithIndifferentAccess.new
    self.non_validating_events = []
  end
  
  def prepare_model model
    # placeholder for adding workflow-related methods
  end
  
  # Note that this can be overridden to swap in different state machine systems
  def fire_event model, event_name
    model.send(event_name)
  end
  
  # Note that this can be overridden to swap in different functionality to determine the allowed events
  def current_allowed_events model, possible_events
    all_events = model.aasm_events_for_current_state
    
    permitted_events = if possible_events
      all_events & possible_events
    else
      all_events
    end || []
    
    permitted_events.map do |event_name|
      [event_name, model.class.event_to_english(event_name)]
    end
    
  end
  
  def state_in model, states
    self_state = model.state
    # Note that before the model is created, it may have a blank state; for now consider that to be the initial state
    self_state = model.class.aasm_initial_state if self_state.blank?
    if states.is_a?(Array)
      !states.select{|cur_state| cur_state.to_s == self_state.to_s}.empty?
    else
      states.to_s == self_state
    end
  end
  
  def track_workflow_changes model, force, change_type
    # If state changed, track a WorkflowEvent
    if force || (model.send(:changed_attributes)['state'] != model.state && !(model.send(:changed_attributes)['state']).blank?)
     unless workflow_disabled
        wfe = WorkflowEvent.create :comment => model.workflow_note, :change_type => change_type, :ip_address => model.workflow_ip_address.to_s, :workflowable_type => model.class.to_s, 
          :workflowable_id => model.id, :old_state => (model.send(:changed_attributes)['state']) || '', :new_state => model.state || '', :created_by  => model.updated_by, :updated_by => model.updated_by
        # p "ESH: creating new wfe=#{wfe.inspect}, errors=#{wfe.errors.inspect}"
        # begin
        #   rails Exception.new 'stack trace'
        # rescue Exception => exception
        #   p "ESH: have an exception #{exception.backtrace.inspect}"
        # end
      end
    end
  end
  
  
  def state_to_english model
    state_to_english_from_state_name model.state
  end
  
  def state_to_english_from_state_name state_name
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

  def add_non_validating_event event
    non_validating_events << event.to_sym
  end
  
  def clear_states_to_english
    states_to_english.clear
  end

  def clear_events_to_english
    events_to_english.clear
  end
  
  def all_events
    events_to_english.keys
  end
  
  def all_states
    states_to_english.keys
  end
end