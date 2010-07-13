module FLuxxUserOrganization
  def self.included(base)
    base.belongs_to :user
    base.belongs_to :organization
    base.belongs_to :locked_by, :class_name => 'User', :foreign_key => 'locked_by_id'
    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta]})

    base.validates_presence_of :user_id
    base.validates_presence_of :organization_id
    base.validates_uniqueness_of :organization_id, :scope => :user_id
    
    # If the userorganization was connected as a primary organization, nil out the primary_organization of the use
    
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