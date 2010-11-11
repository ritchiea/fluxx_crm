class ActionController::ControllerDslUpdate < ActionController::ControllerDsl
  def add_workflow
    if model_class.public_method_defined?(:current_allowed_events)
      
      # Idea here is that after we do the update, try to do the state transition
      self.post do |controller_dsl, controller, model|
        event_action = controller.params[:event_action]
        cur_model = controller.instance_variable_get "@model"
        if event_action
          event_allowed = if controller.respond_to?(:event_allowed?)
            controller.event_allowed?(event_action, cur_model) # Limit them by role
          else
            true
          end

          if event_allowed
            if cur_model.valid? && cur_model.send(event_action)
              cur_model.save(false)
              # Go on with life, the state transition happened uneventfully
            else
              # Something is wrong; send the user back to the edit page
              controller.flash[:error] = I18n.t(:unable_to_promote) + cur_model.errors.full_messages.to_sentence + '.'
              
              extra_options = {:id => cur_model.id}
              controller.redirect_to(controller_dsl.redirect ? controller.send(controller_dsl.redirect, extra_options) : cur_model) 
            end
          else
            p "User is not allowed to do #{event_action}; lacks required permissions"
            raise AASM::InvalidTransition.new "User is not allowed to do #{event_action}; lacks required permissions"
          end
        end
      end
    end
  end
end