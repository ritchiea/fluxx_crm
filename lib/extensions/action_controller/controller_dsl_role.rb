class ActionController::ControllerDslRole < ActionController::ControllerDsl
  # A mapping of events to roles
  attr_accessor :event_role_mappings
  attr_accessor :extract_related_object_proc
  
  def extract_related_object &block
    self.extract_related_object_proc = block
  end
  
  def initialize model_class
    super model_class
    self.event_role_mappings = HashWithIndifferentAccess.new
  end
  
  def add_event_roles event, related_object, roles
    roles = [roles] unless roles.is_a? Array
    
    current_related_mapping = event_role_mappings[event]
    current_related_mapping = {} unless current_related_mapping
    current_mapping = current_related_mapping[related_object]
    current_mapping = [] unless current_mapping
    current_related_mapping[related_object] = roles | current_mapping # Merge in the new roles so we don't have dupes
    event_role_mappings[event] = current_related_mapping
  end
  
  def roles_for_event_and_related_object event, related_object=nil
    current_related_mapping = event_role_mappings[event]
    if current_related_mapping
      current_related_mapping[related_object]
    end || []
  end
  
  def clear_all_event_roles
    event_role_mappings.clear
  end

  def clear_event event
    event_role_mappings[event] = nil
  end
  
  def event_allowed_for_user? user, event, related_object_model=nil
    return true if user.is_admin?
    event_mappings = event_role_mappings[event]
    event_mappings && !(event_mappings.keys.select do |related_object|
      related_object_model.class == related_object && event_mappings[related_object] && !(event_mappings[related_object].select do |role|
        user.has_role?(role, related_object_model)
      end).empty?
    end).empty?
  end
end