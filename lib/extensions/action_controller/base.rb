require 'aasm'
class ActionController::Base
  rescue_from ::AASM::InvalidTransition, :with => :handle_bad_state_transition
  
  def handle_bad_state_transition
    error_message = "Unable to transition to this state"
    flash[:error] = error_message
    render :text => error_message #, :status => 404
  end
  
  def self.insta_role  model_class
    if respond_to?(:role_object) && role_object
      yield role_object if block_given?
    else
      local_role_object = ActionController::ControllerDslRole.new( model_class)
      class_inheritable_reader :role_object
      write_inheritable_attribute :role_object, local_role_object
      yield local_role_object if block_given?
      
      define_method :extract_related_model do |model|
        related_object_model = if role_object.extract_related_object_proc
          role_object.extract_related_object_proc.call model
        else
          model
        end
      end
      
      define_method :has_role_for_event? do |event, model|
        related_object_model = extract_related_model model
        role_object.event_allowed_for_user?(fluxx_current_user, event, related_object_model)
      end
      
      define_method :event_allowed? do |events, model|
        events = [events] unless events.is_a?(Array)
        related_object_model = extract_related_model model
        role_object.check_if_events_allowed?(fluxx_current_user, events, related_object_model)
      end
    end
  end
end
