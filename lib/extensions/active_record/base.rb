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
        if force || changed_attributes['state'] != state
         unless workflow_object.workflow_disabled
            wfe = WorkflowEvent.create :comment => self.workflow_note, :change_type => change_type, :ip_address => self.workflow_ip_address.to_s, :workflowable_type => self.class.to_s, 
              :workflowable_id => self.id, :old_state   => changed_attributes['state'] || '', :new_state => self.state || '', :created_by  => self.updated_by, :updated_by => self.updated_by
          end
        end
      end
    
      define_method :state_to_english do |state_name|
        local_workflow_object.state_to_english state_name
      end
    
      define_method :event_to_english do |event_name|
        local_workflow_object.event_to_english event_name
      end

      define_method :current_allowed_events do
        self.aasm_events_for_current_state.map do |event_name|
          [event_name, self.event_to_english(event_name)]
        end
      end
    end
  end
  
  def self.insta_role
  
  end
end