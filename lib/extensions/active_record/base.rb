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
  end
end