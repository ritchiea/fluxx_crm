module FluxxUsersController
  ICON_STYLE = 'style-users'
  def self.included(base)
    base.skip_before_filter :require_user, :only => [:reset_password, :reset_password_submit]
    base.skip_before_filter :verify_authenticity_token, :only => [:reset_password, :reset_password_submit]
    
    base.insta_index User do |insta|
      insta.template = 'user_list'
      insta.icon_style = ICON_STYLE
      insta.create_link_title = "New Person"
      insta.filter_template = 'users/user_filter'
      insta.order_clause = 'last_name asc, first_name asc'
      insta.pre do |controller_dsl|
        if params[:related_organization_id]
          rel_org_id = params[:related_organization_id]
          org = Organization.find rel_org_id
          if org
            self.pre_models ||= org.related_users nil
          end
        end
      end
    end
    base.insta_show User do |insta|
      insta.template = 'user_show'
      insta.icon_style = ICON_STYLE
    end
    base.insta_new User do |insta|
      insta.template = 'user_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit User do |insta|
      insta.template = 'user_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_post User do |insta|
      insta.template = 'user_form'
      insta.icon_style = ICON_STYLE
      
      # Add in a post method to create a user org if the organization_id param is passed in
      insta.post do |triple|
        controller_dsl, model, outcome = triple
        # Check to see if there was an organization passed in to use to create a user organization
        user = model
        org = Organization.where(:id => user.temp_organization_id).first
        if org 
          user_org = UserOrganization.where(['organization_id = ? AND user_id = ?', org.id, user.id]).first
          user_org || UserOrganization.create(:user => user, :organization => org, :title => user.temp_organization_title)
        end
      end
    end
    
    base.insta_put User do |insta|
      insta.template = 'user_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_delete User do |insta|
      insta.template = 'user_form'
      insta.icon_style = ICON_STYLE
    end

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def impersonate
      user = User.where(:id => params[:user_id], :deleted_at => nil).first
      if user
        redirect_to user_sessions_impersonate_path(:user_session => {:login => user.login, :password => user.saml_store})
      else
        redirect_back_or_default
      end
    end
    
    def reset_password
      @user = User.find_using_perishable_token(params[:reset_password_code], 1.week) || (raise Exception)
    end

    def reset_password_submit
      @user = User.find_using_perishable_token(params[:reset_password_code], 1.week) || (raise Exception)
      @user.active = true
      if @user.update_attributes(params[:user].merge({:active => true}))
        flash[:notice] = "Successfully reset password."
        redirect_back_or_default dashboard_index_path
      else
        flash[:notice] = "There was a problem resetting your password."
        render :action => :reset_password
      end
    end
   
    USER_QUERY_SELECT = "select users.id, first_name, last_name, soundex(first_name) first_name_soundex, soundex(last_name) last_name_soundex, email, personal_email, salutation, prefix, middle_initial, personal_phone, personal_mobile, personal_fax, personal_street_address, personal_street_address2, personal_city, (select name from geo_states where id = personal_geo_state_id) geo_state_name, (select name from geo_countries where id = personal_geo_country_id) geo_country_name, 
     personal_postal_code, work_phone, work_fax, other_contact
     "

    def dedupe_list
      @users = User.connection.execute "#{USER_QUERY_SELECT}
        from users
        where deleted_at is null 
         order by first_name_soundex, last_name_soundex, first_name, last_name "
      render :layout => false
    end
    
    def dedupe_prep
      @users = User.connection.execute ClientStore.send(:sanitize_sql, ["#{USER_QUERY_SELECT}
        from users where id in (?) and deleted_at is null", params[:user_id]])
      render :action => 'dedupe_prep', :layout => false
    end
    
    def dedupe_complete
      @users = User.where(:id => params[:user_id], :deleted_at => nil).all
      @primary_user = User.where(:id => params[:primary_user_id], :deleted_at => nil).first
      if @users && @primary_user
        (@users - [@primary_user]).each do |dupe_user|
          p "ESH: merging dupe_user #{dupe_user.id} into primary_user #{@primary_user.id}"
          @primary_user.merge dupe_user
        end
        # TODO ESH: swap this out when it runs inside fluxx
        # fluxx_redirect users_dedupe_path
        redirect_to users_dedupe_path
      else
        dedupe_prep
      end
    end
    
  end
end