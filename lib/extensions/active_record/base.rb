class ActiveRecord::Base
  
  def self.insta_favorite
    has_many :favorites, :as => :favorable
    define_method :is_favorite_for? do |user|
      Favorite.find :first, :conditions => {:user_id => user.id, :favorable_type => self.class.name, :favorable_id => self.id}
    end
    
    define_method :favorite_user_ids do
      favorites.map{|fav| fav.user_id}.flatten.compact
    end
    
  end
  
  def self.insta_workflow
    if respond_to?(:workflow_object) && workflow_object
      yield workflow_object if block_given?
    else
      local_workflow_object = ActiveRecord::ModelDslWorkflow.new(self)
      class_inheritable_reader :workflow_object
      write_inheritable_attribute :workflow_object, local_workflow_object
      yield local_workflow_object if block_given?
      
      def update_attribute_without_log_with_specific key, value
        if self.class.respond_to?(:without_workflow)
          self.class.without_workflow do
            update_attribute_without_log_without_specific key, value
          end
        else
          update_attribute_without_log_without_specific key, value
        end
      end
      alias_method_chain :update_attribute_without_log, :specific
      
      def update_attributes_without_log_with_specific attr_map
        if self.class.respond_to?(:without_workflow)
          self.class.without_workflow do
            update_attributes_without_log_without_specific attr_map
          end
        else
          update_attributes_without_log_without_specific attr_map
        end
      end
      alias_method_chain :update_attributes_without_log, :specific
      

      self.instance_eval do
        attr_accessor :workflow_note
        attr_accessor :workflow_ip_address
        before_create :track_workflow_create
        before_update :track_workflow_update
        before_destroy :track_workflow_destroy

        
        def without_workflow(&block)
          workflow_was_disabled = workflow_object.workflow_disabled
          workflow_object.workflow_disabled = true
          returning(block.call) { workflow_object.workflow_disabled = false unless workflow_was_disabled }
        end
        
        def event_to_english event_name
          workflow_object.event_to_english event_name
        end
        
        def state_to_english_translation state_name
          workflow_object.state_to_english state_name
        end
        
        def workflow_states
          workflow_object.all_states
        end
        
        def workflow_events
          workflow_object.all_events
        end
      end
      
      define_method :is_non_validating_event? do |event_name|
        local_workflow_object.non_validating_events.include? event_name.to_sym
      end
      
      define_method :state_in do |states|
        self_state = self.state
        # Note that before the model is created, it may have a blank state; for now consider that to be the initial state
        self_state = self.class.aasm_initial_state if self_state.blank?
        if states.is_a?(Array)
          !states.select{|cur_state| cur_state.to_s == self_state.to_s}.empty?
        else
          states.to_s == self_state
        end
      end

      define_method :track_workflow_create do
        track_workflow_changes true, 'create'
      end
      define_method :track_workflow_update do
        track_workflow_changes false, 'update'
      end
      define_method :track_workflow_destroy do
        track_workflow_changes true, 'destroy'
      end
    
      define_method :track_workflow_changes do |force, change_type|
        # If state changed, track a WorkflowEvent
        if force || (changed_attributes['state'] != state && !changed_attributes['state'].blank?)
         unless workflow_object.workflow_disabled
            wfe = WorkflowEvent.create :comment => self.workflow_note, :change_type => change_type, :ip_address => self.workflow_ip_address.to_s, :workflowable_type => self.class.to_s, 
              :workflowable_id => self.id, :old_state   => changed_attributes['state'] || '', :new_state => self.state || '', :created_by  => self.updated_by, :updated_by => self.updated_by
            # p "ESH: creating new wfe=#{wfe.inspect}"
            # begin
            #   rails Exception.new 'stack trace'
            # rescue Exception => exception
            #   p "ESH: have an exception #{exception.backtrace.inspect}"
            # end
          end
        end
      end
    
      define_method :state_to_english do
        local_workflow_object.state_to_english self.state
      end
    
      # Allow a parameter possible_events which is an array of legal event names that are being looked for
      define_method :current_allowed_events do |*optional|
        possible_events, *ignored = *optional
        all_events = self.aasm_events_for_current_state
        
        permitted_events = if possible_events
          all_events & possible_events
        else
          all_events
        end || []
        
        permitted_events.map do |event_name|
          [event_name, self.class.event_to_english(event_name)]
        end
      end
    end
  end
  
  def state_past state_array, marker_state, current_state
    state_array = state_array.map{|elem| elem.to_s}
    marker_state = marker_state.to_s
    current_state = current_state.to_s
    cur_state_index = state_array.index current_state
    marker_state_index = state_array.index marker_state
    cur_state_index > marker_state_index if cur_state_index && marker_state_index
  end
  
  def state_past_or_equal state_array, marker_state, current_state
    state_array = state_array.map{|elem| elem.to_s}
    marker_state = marker_state.to_s
    current_state = current_state.to_s
    cur_state_index = state_array.index current_state
    marker_state_index = state_array.index marker_state
    cur_state_index >= marker_state_index if cur_state_index && marker_state_index
  end
end