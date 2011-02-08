class ActionController::ControllerDslUpdate < ActionController::ControllerDsl
  def add_workflow
    if model_class.public_method_defined?(:current_allowed_events)
      
      self.pre do |conf|
        self.pre_model = conf.load_existing_model params
        # validate documents on state change/event actions - except for send_back or reject/unreject events
        if params[:event_action]
          if self.pre_model.respond_to?(:promotion_event)
            self.pre_model.promotion_event = true 
          else
            ActiveRecord::Base.logger.warn "Class #{self.pre_model.class.name} does not have promotion_event accessor defined, you should probably add it for workflow"
          end
        end
      end
      
      # Idea here is that after we do the update, try to do the state transition
      self.post do |pair|
        controller_dsl, model = pair
        event_action = params[:event_action]
        if event_action
          event_allowed = if respond_to?(:event_allowed?)
            event_allowed?(event_action, model) # Limit them by role
          else
            true
          end

          if event_allowed
            if (model.is_non_validating_event?(event_action) || model.valid?) && model.send(event_action)
              model.save(:validate => false)
              # Go on with life, the state transition happened uneventfully
            else
              # Something is wrong; send the user back to the show page
              flash[:error] = I18n.t(:unable_to_promote) + model.errors.full_messages.to_sentence + '.'
              
              extra_options = {:id => model.id}
              redirect_to(controller_dsl.redirect ? send(controller_dsl.redirect, extra_options) : model) 
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