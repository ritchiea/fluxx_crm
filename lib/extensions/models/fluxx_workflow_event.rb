module FluxxWorkflowEvent
  def self.included(base)
    base.belongs_to :workflowable, :polymorphic => true
    base.belongs_to :created_by,  :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'

    base.validates_presence_of :old_state
    base.validates_presence_of :new_state
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
  end
end