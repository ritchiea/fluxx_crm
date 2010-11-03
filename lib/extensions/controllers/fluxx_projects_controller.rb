module FluxxProjectsController
  ICON_STYLE = 'style-projects'
  def self.included(base)
    base.insta_index Project do |insta|
      insta.template = 'project_list'
      insta.order_clause = 'created_at desc'
      insta.icon_style = ICON_STYLE
    end
    base.insta_show Project do |insta|
      insta.template = 'project_show'
      insta.icon_style = ICON_STYLE
    end
    base.insta_new Project do |insta|
      insta.template = 'project_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit Project do |insta|
      insta.template = 'project_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_post Project do |insta|
      insta.template = 'project_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_put Project do |insta|
      insta.template = 'project_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_delete Project do |insta|
      insta.template = 'project_form'
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