class ActionController::Base
  rescue_from AASM::InvalidTransition, :with => :handle_bad_state_transition
  
  def handle_bad_state_transition
    error_message = "Unable to transition to this state"
    flash[:error] = error_message
    render :text => error_message #, :status => 404
  end
end