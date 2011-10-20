module FluxxUsersController
  ICON_STYLE = 'style-users'
  def self.included(base)
    base.insta_index User do |insta|
      insta.template = 'user_list'
      insta.icon_style = ICON_STYLE
      insta.filter_template = 'users/user_filter'
      insta.order_clause = 'last_name asc, first_name asc'
      insta.pre do |controller_dsl|
        if params[:related_organization_id]
          rel_org_id = params[:related_organization_id]
          # TODO ESH: refactor this into organization.rb so we can do org.all_related_users
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
  end
end