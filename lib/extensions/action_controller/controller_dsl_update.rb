class ActionController::ControllerDslUpdate < ActionController::ControllerDsl
  def add_workflow
    if model_class.public_method_defined?(:current_allowed_events)
      
      # Idea here is that after we do the update, try to do the state transition
      self.post do |pair|
        controller_dsl, model = pair
        event_action = params[:event_action]
        cur_model = instance_variable_get "@model"
        if event_action
          event_allowed = if respond_to?(:event_allowed?)
            event_allowed?(event_action, cur_model) # Limit them by role
          else
            true
          end

          if event_allowed
            if cur_model.valid? && cur_model.send(event_action)
              cur_model.save(:validate => false)
              # Go on with life, the state transition happened uneventfully
            else
              # Something is wrong; send the user back to the show page
              flash[:error] = I18n.t(:unable_to_promote) + cur_model.errors.full_messages.to_sentence + '.'
              
              extra_options = {:id => cur_model.id}
              redirect_to(controller_dsl.redirect ? send(controller_dsl.redirect, extra_options) : cur_model) 
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