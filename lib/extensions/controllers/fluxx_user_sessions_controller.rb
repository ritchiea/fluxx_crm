module FluxxUserSessionsController
  extend FluxxModuleHelper

  ICON_STYLE = 'style-request-amendments'

  when_included do
    skip_before_filter :require_user, :only => [:new, :create, :forgot_password, :reset_password]
    before_filter :require_user, :only => :destroy
    skip_before_filter :verify_authenticity_token, :only => [:new, :create, :forgot_password, :reset_password]
  end
  
  class_methods do
  end
  
  instance_methods do
    def new
      response.headers['fluxx_template'] = 'login'
      @user_session = UserSession.new
      respond_to do |format|
        format.html do
          if Fluxx.config(:classic_login_laf) == "1"
            render :action => 'new.html.haml'
          else
            render(:action => :portal, :layout => "portal")
          end
        end
        format.json do
          render :action => 'new.html.haml'
        end
      end
    end

    def impersonate
      create
    end

    def create
      @user_session = UserSession.new(params[:user_session])
      User.suspended_delta(false) do
        User.without_realtime do
          User.without_auditing do
              if @user_session.save
                # ESH: total hack to not re-index delta; I couldn't find an appropriate place to tell TS not to toggle delta
                # this is bad because if somebody had legitimately toggled the delta to reindex this user, it will not get reindexed
                User.connection.execute User.send(:sanitize_sql, ["update users set delta = 0 where id = ?", @user_session.user.id])
                flash[:notice] = "Login successful!"
                response.headers['fluxx_result_success'] = 'create'
                if @user_session.user.is_grantee?
                  redirect_back_or_default grantee_portal_index_path
                elsif @user_session.user.is_reviewer?
                  redirect_back_or_default reviewer_portal_index_path
                else
                  redirect_back_or_default dashboard_index_path
                end
              else
                response.headers['fluxx_result_failure'] = 'create'
                if params["user_session"] && params["user_session"]["portal"]
                    render :action => :portal, :layout => "portal"
                else
                  render :action => :new
                end
              end
          end
        end
      end
    end

    def destroy
      current_user_session.destroy
      clear_current_user
      flash[:notice] = "Logout successful!"
      redirect_back_or_default new_user_session_url
    end
    
    def forgot_password
      @user_session = UserSession.new()
    end

    def forgot_password_lookup_email
      if current_user
        redirect_to dashboard_path
      else
        user = User.find_by_email(params[:user_session][:email])
        if user
          user.send_forgot_password! self
          flash[:notice] = "A link to reset your password has been mailed to you."
        else
          flash[:notice] = "Email #{params[:user_session][:email]} wasn't found.  Perhaps you used a different one?  Or never registered or something?"
          render :action => :forgot_password
        end
      end
    end
    

    def portal
      if !current_user_session.nil?
        current_user_session.destroy
        clear_current_user
      end
      response.headers['fluxx_template'] = 'login'
      @user_session = UserSession.new
      respond_to do |format|
        format.html do
          render :action => :portal, :layout => "portal"
        end
      end
    end
  end
end