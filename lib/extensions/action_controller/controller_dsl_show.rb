class ActionController::ControllerDslShow < ActionController::ControllerDsl
  def add_workflow
    if model_class.public_method_defined?(:current_allowed_events)
      self.footer_template = 'insta/show_buttons'
      self.post do |config, controller, model|
        action_buttons = if model
          model.current_allowed_events
        else
          []
        end
        controller.send :instance_variable_set, "@action_buttons", action_buttons
      end
    else
      p "For class #{model_class}, you may want to call insta_workflow so that current_allowed_events is defined"
    end
  end
end