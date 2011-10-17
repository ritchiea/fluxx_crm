module FluxxAlertTransitionState
  extend FluxxModuleHelper

  SEARCH_ATTRIBUTES = [:created_at, :updated_at, :id]
  
  when_included do
    belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    belongs_to :alert
    belongs_to :machine_state

    acts_as_audited({:full_model_enabled => false, :except => [:created_by_id, :updated_by_id, :delta, :updated_by, :created_by, :audits]})

    insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
      insta.derived_filters = {}
    end

    insta_export
    
  end
  

  class_methods do
  end
end