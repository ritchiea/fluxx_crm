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
          self.pre_models ||= User.find_by_sql ['SELECT users.* FROM users, user_organizations 
                                 WHERE user_organizations.organization_id IN 
                                 (select distinct(id) from (select id from organizations where id = ? 
                                  union select id from organizations where parent_org_id = ? 
                                  union select id from organizations where parent_org_id = (select parent_org_id from organizations where id = ?) and parent_org_id is not null
                                  union select parent_org_id from organizations where id = ?) all_orgs where id is not null) 
                                 AND user_organizations.user_id = users.id and users.deleted_at is null', rel_org_id, rel_org_id, rel_org_id, rel_org_id]
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