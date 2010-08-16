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
    local_workflow_object = @workflow_object = ActiveRecord::ModelDslWorkflow.new(self)
    yield @workflow_object if block_given?
    
    self.instance_eval do
      attr_accessor :workflow_note
      attr_accessor :workflow_ip_address
      before_create :track_workflow_create
      before_update :track_workflow_update
      before_destroy :track_workflow_destroy
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
        wfe = WorkflowEvent.create :comment => self.workflow_note, :change_type => change_type, :ip_address => self.workflow_ip_address.to_s, :workflowable_type => self.class.to_s, 
          :workflowable_id => self.id, :old_state   => changed_attributes['state'] || '', :new_state => self.state || '', :created_by  => self.updated_by, :updated_by => self.updated_by
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