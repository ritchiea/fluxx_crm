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
  
  before_filter :require_user
  protect_from_forgery

  before_filter :set_time_zone

  def set_time_zone
    Time.zone = current_user.time_zone if current_user && current_user.time_zone
  end

  helper_method :current_user_session, :clear_current_user, :current_user
  
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end
  
  def clear_current_user
    @current_user = nil if defined?(@current_user)
    @current_user_session = nil if defined?(@current_user_session)
  end

  def current_user
    User.suspended_delta do
      User.without_realtime do
        User.without_auditing do
          if defined?(@current_user)
            @current_user 
          else
            @current_user = current_user_session && current_user_session.user
          end
        end
      end
    end
  end
  
  protected
    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        # flash[:notice] = "You must be logged out to access this page"
        redirect_to dashboard_index_path
        return false
      end
    end
    
    def store_location
      session[:return_to] = request.request_uri
    end
    
    def redirect_back_or_default(default)
      redirect_to(default || dashboard_index_path)
      session[:return_to] = nil
    end
end
