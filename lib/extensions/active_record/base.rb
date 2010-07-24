class ActiveRecord::Base
  def self.insta_workflow
    local_workflow_object = @workflow_object = ActiveRecord::ModelDslWorkflow.new(self)
    yield @workflow_object if block_given?
    
    self.instance_eval do
      attr_accessor :workflow_note
      attr_accessor :workflow_ip_address
      before_save :track_workflow_changes
    end
    
    define_method :track_workflow_changes do
      # If state changed, track a WorkflowEvent
      if changed_attributes['state'] != state
        WorkflowEvent.create :comment => self.workflow_note, :ip_address => self.workflow_ip_address.to_s, :workflowable_type => self.class.to_s, 
          :workflowable_id => self.id, :old_state   => changed_attributes['state'], :new_state   => self.state, :created_by  => self.updated_by, :updated_by => self.updated_by
      end
    end
    
    define_method :state_to_english do |state_name|
      local_workflow_object.state_to_english state_name
    end
    
    define_method :event_to_english do |event_name|
      local_workflow_object.event_to_english event_name
    end

    define_method :current_allowed_events do
      self.aasm_events_for_current_state
    end
  end
end