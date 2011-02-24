class ActiveRecord::ModelDslWorkflow < ActiveRecord::ModelDsl
  # A custom SQL query to be executed when the export is run
  attr_accessor :sql_query
  # A mapping from symbol to english word for states
  attr_accessor :states_to_english
  # A mapping from symbol to category
  attr_accessor :states_to_category
  # An ordered list of states
  attr_accessor :ordered_states
  # A mapping from symbol to english word for events
  attr_accessor :events_to_english
  # A list of events to skip validating on when changing state
  attr_accessor :non_validating_events
  # If this is true, the workflow updates will not execute
  attr_accessor :workflow_disabled

  def initialize model_class
    super model_class
    self.states_to_english = HashWithIndifferentAccess.new
    self.states_to_category = HashWithIndifferentAccess.new
    self.events_to_english = HashWithIndifferentAccess.new
    self.ordered_states = []
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
  
  # TODO ESH: change the below to use metadata added to describe the type of state when calling add_state_to_english for example
  def in_new_state? model
    model.state.to_s =~ /^new/ || model.state.blank?
  end

  def in_reject_state? model
    model.state.to_s =~ /^reject/
  end

  def in_workflow_state? model
    !(model.in_new_state || model.in_reject_state || model.in_sentback_state)
  end

  def in_sentback_state? model
    model.state.to_s =~ /sent_back/
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
  
  def add_state_to_english new_state, state_name, category_names=nil
    states_to_english[new_state.to_sym] = state_name
    if category_names
      category_states = states_to_category[new_state.to_sym]
      category_states = [] unless category_states
      if category_names.is_a? Array
        category_states.each{|cn| category_states << cn.to_s}
      else
        category_states << category_names.to_s 
      end
      states_to_category[new_state.to_sym] = category_states
    end
    ordered_states << new_state
  end

  def add_event_to_english new_event, event_name
    events_to_english[new_event.to_sym] = event_name
  end

  def add_non_validating_event event
    non_validating_events << event.to_sym
  end
  
  def clear_states_to_english
    ordered_states.clear
    states_to_category.clear
    states_to_english.clear
  end

  def clear_events_to_english
    events_to_english.clear
  end
  
  def all_events
    events_to_english.keys
  end
  
  def all_states
    ordered_states
  end

  def all_states_with_category category
    if category
      ordered_states.select do |state_name| 
        if state_name
          cur_categories = states_to_category[state_name.to_sym]
          if cur_categories
            !cur_categories.select{|cur_category| cur_category.to_s == category.to_s}.empty?
          end
        end
      end
    end || []
  end
  
  def is_reject_state? state_name
     state_name.to_s =~ /reject/ || state_name.to_s =~ /cancel/
  end
  def is_new_state? state_name
    state_name.to_s =~ /^new/
  end
  def is_sent_back_state? state_name
    state_name.to_s =~ /sent_back/
  end
  
  def all_workflow_states
    all_states - all_rejected_states - all_sent_back_states
  end
  
  def all_rejected_states
    ordered_states.select{|st| is_reject_state? st.to_s }
  end

  def all_new_states
    ordered_states.select{|st| is_new_state? st.to_s }
  end

  def all_sent_back_states
    ordered_states.select{|st| is_sent_back_state? st.to_s }
  end
  
  def extract_all_event_types model_class
    model_class.aasm_events.keys.map do |event_name|
      event_to_state = model_class.aasm_events[event_name].instance_variable_get('@transitions').first.instance_variable_get '@to' rescue nil
      [event_name, event_to_state]
    end
  end

  def all_events model_class
    extract_all_event_types(model_class).map{|pair| pair.first}
  end
  
  def all_workflow_events model_class
    all_events = extract_all_event_types(model_class).map{|pair| pair.first}
    all_events - all_rejected_events(model_class) - all_new_events(model_class) - all_sent_back_events(model_class)
  end

  def all_rejected_events model_class
    extract_all_event_types(model_class).select{|pair| is_reject_state?(pair[1])}.map{|pair| pair.first}
  end
  
  def all_new_events model_class
    extract_all_event_types(model_class).select{|pair| is_new_state?(pair[1])}.map{|pair| pair.first}
  end

  def all_sent_back_events model_class
    extract_all_event_types(model_class).select{|pair| is_sent_back_state?(pair[1])}.map{|pair| pair.first}
  end
end