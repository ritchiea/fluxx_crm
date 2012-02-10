module FluxxWorkTasksController
  ICON_STYLE = 'style-work-tasks'
  def self.included(base)
    base.insta_index WorkTask do |insta|
      insta.template = 'work_task_list'
      insta.filter_title = "WorkTasks Filter"
      insta.filter_template = 'work_tasks/work_task_filter'
      insta.order_clause = 'due_at asc'
      insta.icon_style = ICON_STYLE
      insta.create_link_title = "New Task"
    end
    base.insta_show WorkTask do |insta|
      insta.template = 'work_task_show'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_new WorkTask do |insta|
      insta.template = 'work_task_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit WorkTask do |insta|
      insta.template = 'work_task_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_post WorkTask do |insta|
      insta.template = 'work_task_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_put WorkTask do |insta|
      insta.template = 'work_task_form'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_delete WorkTask do |insta|
      insta.template = 'work_task_form'
      insta.icon_style = ICON_STYLE
    end

    base.insta_related WorkTask do |insta|      
      insta.add_related do |related|
        related.display_name = 'People'
        related.add_title_block do |model|
          model.full_name if model
        end
        related.for_search do |model|
          model.related_users
        end
        related.display_template = '/users/related_users'
      end
      insta.add_related do |related|
        related.display_name = 'Projects'
        related.add_title_block do |model|
          model.title if model
        end
        related.for_search do |model|
          model.related_projects
        end
        related.display_template = '/projects/related_project'
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