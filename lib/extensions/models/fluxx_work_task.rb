module FluxxWorkTask
  SEARCH_ATTRIBUTES = [:created_at, :updated_at, :id, :taskable_type, :taskable_id, :assigned_user_id, :task_completed, :due_at]
  
  def self.included(base)
    base.validates_presence_of :task_text
    base.belongs_to :taskable, :polymorphic => true
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.belongs_to :assigned_user, :class_name => 'User', :foreign_key => 'assigned_user_id'
    base.has_many :wiki_documents, :as => :model, :conditions => {:deleted_at => nil}
    base.has_many :model_documents, :as => :documentable
    base.has_many :notes, :as => :notable, :conditions => {:deleted_at => nil}
    base.before_save :adjust_completed_at

    base.acts_as_audited({:full_model_enabled => false, :except => [:created_by_id, :updated_by_id, :delta, :updated_by, :created_by, :audits]})

    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
      insta.derived_filters = {:due_in_days => (lambda do |search_with_attributes, request_params, name, value|
          value = value.first if value && value.is_a?(Array)
          if value.to_s.is_numeric?
            due_date_check = Time.now + value.to_i.days
            search_with_attributes[:due_at] = (Time.now.to_i..due_date_check.to_i)
            search_with_attributes[:task_completed] = false
          end || {}
        end),
        :overdue_by_days => (lambda do |search_with_attributes, request_params, name, value|
          value = value.first if value && value.is_a?(Array)
          if value.to_s.is_numeric?
            due_date_check = Time.now - value.to_i.days
            search_with_attributes[:due_at] = (0..due_date_check.to_i)
            search_with_attributes[:task_completed] = false
          end || {}
        end),
      }
    end

    base.insta_multi
    base.insta_lock
    base.insta_realtime do |insta|
      insta.delta_attributes = SEARCH_ATTRIBUTES
      insta.updated_by_field = :updated_by_id
    end
    base.insta_json do |insta|
      insta.add_only 'request_id'
      insta.add_only 'name'
      insta.add_only 'task_text'
      insta.add_only 'taskable_type'
      insta.add_only 'due_at'
      insta.add_only 'task_order'
      insta.add_only 'task_completed'
      insta.add_only 'completed_at'
      
      insta.copy_style :simple, :detailed
    end

    base.insta_template do |insta|
      insta.entity_name = 'work_task'
      insta.add_methods []
      insta.remove_methods [:id]
    end

    base.insta_favorite
    base.insta_utc do |insta|
      insta.time_attributes = [:due_at]
    end

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end
  

  module ModelClassMethods
  end
  
  module ModelInstanceMethods
    def adjust_completed_at
      self.completed_at = if task_completed
        Time.now
      else
        nil
      end
    end
    
    def related_users
      [assigned_user]
    end
    
    def related_projects
      result = []
      # AML: This is throwing an error for some reason for certain taksks
      t = taskable rescue nil
      result << t if t.is_a?(Project)
      result
    end
  end
end