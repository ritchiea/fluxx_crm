module FluxxProject
  SEARCH_ATTRIBUTES = [:created_at, :updated_at, :title]

  def self.included(base)
    base.has_many :project_organizations
    base.belongs_to :lead_user, :class_name => 'User', :foreign_key => :lead_user_id
    
    base.acts_as_audited
    
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
    end
    base.insta_export
    base.insta_multi
    base.insta_favorite
    
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