module FluxxProjectListItem
  SEARCH_ATTRIBUTES = [:created_at, :updated_at]

  def self.included(base)
    base.belongs_to :project_list
    base.belongs_to :assigned_user
    base.acts_as_audited
    
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
    end
    base.insta_export
    base.insta_multi
    
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