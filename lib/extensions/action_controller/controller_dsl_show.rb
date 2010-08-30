class ActionController::ControllerDslShow < ActionController::ControllerDsl
  def add_workflow
    if model_class.public_method_defined?(:current_allowed_events)
      self.footer_template = 'insta/show_buttons'
      self.post do |config, controller, model|
        action_buttons = if model
          event_pairs = model.current_allowed_events    # Find all events
          event_names = event_pairs.map {|event| event.first}
          allowed_event_names = if controller.respond_to? :event_allowed?
            controller.event_allowed?(event_names, model) # Limit them by role
          else
            event_names
          end
          allowed_event_names && event_pairs.select{|event_pair| allowed_event_names.include?(event_pair.first)}
        end || []
        controller.send :instance_variable_set, "@action_buttons", action_buttons
      end
    else
      p "For class #{model_class}, you may want to call insta_workflow so that current_allowed_events is defined"
    end
  end
end