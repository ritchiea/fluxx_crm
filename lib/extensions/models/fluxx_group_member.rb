module FLuxxGroupMember
  def self.included(base)
    base.belongs_to :groupable, :polymorphic => true
    base.belongs_to :group
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :modified_by, :class_name => 'User', :foreign_key => 'modified_by_id'
    
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