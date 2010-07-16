module FLuxxUserOrganization
  def self.included(base)
    base.belongs_to :user
    base.belongs_to :organization
    base.belongs_to :locked_by, :class_name => 'User', :foreign_key => 'locked_by_id'
    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta]})

    base.validates_presence_of :user_id
    base.validates_presence_of :organization_id
    base.validates_uniqueness_of :organization_id, :scope => :user_id
    base.has_many :primary_user_organizations_users, :class_name => 'User', :foreign_key => :primary_user_organization_id
    
    base.insta_search
    base.insta_export
    base.insta_lock
    
    # If the userorganization was connected as a primary organization, nil out the primary_organization of the use
    base.before_save :clear_out_related_primary_organizations
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def clear_out_related_primary_organizations
      primary_user_organizations_users.each do |user|
        other_user_orgs = user.user_organizations.select {|uo| uo.id != self.id}
        if other_user_orgs
          user.update_attributes :primary_user_organization => other_user_orgs.first
        else
          user.update_attributes :primary_user_organization => nil
        end
      end
    end
  end
end