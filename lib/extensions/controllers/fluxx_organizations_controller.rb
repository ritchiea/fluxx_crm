module FluxxOrganizationsController
  ICON_STYLE = 'style-organizations'
  def self.included(base)
    base.insta_index Organization do |insta|
      insta.template = 'organization_list'
      insta.order_clause = 'name asc'
      insta.search_conditions = {:parent_org_id => 0}
      insta.icon_style = ICON_STYLE
    end
    base.insta_show Organization do |insta|
      insta.template = 'organization_show'
      insta.icon_style = ICON_STYLE
    end
    base.insta_new Organization do |insta|
      insta.template = 'organization_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit Organization do |insta|
      insta.template = 'organization_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_post Organization do |insta|
      insta.template = 'organization_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_put Organization do |insta|
      insta.template = 'organization_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_delete Organization do |insta|
      insta.template = 'organization_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_related Organization do |insta|
      # NOTE ESH: this causes tests to fail
      # insta.add_related do |related|
      #   related.display_name = 'People'
      #   related.related_class = User
      #   related.search_id = :organization_id
      #   related.extra_condition = {:deleted_at => 0}
      #   related.max_results = 20
      #   related.order = 'last_name asc, first_name asc'
      #   related.display_template = '/users/related_users'
      # end
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