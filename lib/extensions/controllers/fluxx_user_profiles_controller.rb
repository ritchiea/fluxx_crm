module FluxxUserProfilesController
  ICON_STYLE = 'style-user-profiles'
  def self.included(base)
    base.insta_index Role do |insta|
      insta.template = 'user_profile_list'
      insta.order_clause = 'name asc, updated_at desc'
      insta.icon_style = ICON_STYLE
      insta.suppress_model_iteration = true
    end
    base.insta_show Role do |insta|
      insta.template = 'user_profile_show'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_new Role do |insta|
      insta.template = 'user_profile_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit Role do |insta|
      insta.template = 'user_profile_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_post Role do |insta|
      insta.template = 'user_profile_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_put Role do |insta|
      insta.template = 'user_profile_form'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_delete Role do |insta|
      insta.template = 'user_profile_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_related Role do |insta|
      insta.add_related do |related|
      end
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
