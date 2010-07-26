class ActionController::ControllerDslUpdate < ActionController::ControllerDsl
  def add_workflow
    p "ESH: in ControllerDslUpdate::add_workflow"
    if model_class.public_method_defined?(:current_allowed_events)
      self.pre do |config, controller|
        event_action = controller.params[:event_action]
        controller.pre_model = config.load_existing_model controller.params, nil
        controller.pre_model.send event_action
        p "ESH: event params is #{event_action}"
      end
    end
  end
end