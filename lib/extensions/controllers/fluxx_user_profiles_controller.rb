module FluxxUserProfilesController
  ICON_STYLE = 'style-user-profiles'
  def self.included(base)
    base.insta_index UserProfile do |insta|
      insta.template = 'user_profile_list'
      insta.order_clause = 'name asc, updated_at desc'
      insta.icon_style = ICON_STYLE
      insta.suppress_model_iteration = true
    end
    base.insta_show UserProfile do |insta|
      insta.template = 'user_profile_show'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_new UserProfile do |insta|
      insta.template = 'user_profile_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit UserProfile do |insta|
      insta.template = 'user_profile_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_post UserProfile do |insta|
      insta.template = 'user_profile_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_put UserProfile do |insta|
      insta.template = 'user_profile_form'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_delete UserProfile do |insta|
      insta.template = 'user_profile_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_related UserProfile do |insta|
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
