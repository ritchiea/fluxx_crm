class ActionController::ControllerDslUpdate < ActionController::ControllerDsl
  def add_workflow
    if model_class.public_method_defined?(:current_allowed_events)
      self.pre do |config, controller|
        event_action = controller.params[:event_action]
        controller.pre_model = config.load_existing_model controller.params, nil
        if event_action
          event_allowed = if controller.respond_to? :event_allowed?
            controller.event_allowed?(event_action, controller.pre_model) # Limit them by role
          else
            true
          end
        
          if event_allowed
            controller.pre_model.send event_action
          else
            p "User is not allowed to do #{event_action}; lacks required permissions"
            raise AASM::InvalidTransition.new "User is not allowed to do #{event_action}; lacks required permissions"
          end
        end
      end
    end
  end
end