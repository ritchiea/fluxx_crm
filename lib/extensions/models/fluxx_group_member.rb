module FluxxGroupMember
  SEARCH_ATTRIBUTES = [:groupable_type, :groupable_id]

  def self.included(base)
    base.belongs_to :groupable, :polymorphic => true
    base.belongs_to :group
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.after_save :update_related_object
    
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
    end
    base.insta_multi
    base.insta_export
    base.insta_lock
    base.acts_as_audited
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def update_related_object
      # Force the groupable object to update
      related_type = Object.const_get groupable_type rescue nil
      if related_type && groupable.respond_to?(:delta)
        related_type.update_all 'delta = 1', ['id = ?', groupable_id]
        o = related_type.find(groupable_id)
        o.delta = 1
        o.save 
      end
    end
  end
end