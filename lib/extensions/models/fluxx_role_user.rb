module FluxxRoleUser
  def self.included(base)
    base.belongs_to :roleable, :polymorphic => true
    base.belongs_to :created_by,  :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.belongs_to :user

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    def find_by_roleable related_object
      if related_object
        self.where(:roleable_id => related_object.id, :roleable_type => related_object.class.name)
      else
        []
      end
    end
    
  end

  module ModelInstanceMethods
  end
end