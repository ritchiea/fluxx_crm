class User < ActiveRecord::Base
  has_many :user_organizations, :conditions => 'user_organizations.deleted_at IS NULL'
  has_many :organizations, :through => :user_organizations
  belongs_to :personal_geo_country, :class_name => 'GeoCountry', :foreign_key => :personal_geo_state_id
  belongs_to :personal_geo_state, :class_name => 'GeoState', :foreign_key => :personal_geo_state_id
  belongs_to :primary_user_organization, :class_name => 'UserOrganization', :foreign_key => :primary_user_organization_id
  belongs_to :primary_organization, :class_name => 'Organization', :include => :primary_user_organization, :foreign_key => 'organization_id'
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
  belongs_to :modified_by, :class_name => 'User', :foreign_key => 'modified_by_id'
  acts_as_audited({:full_model_enabled => true, :except => [:activated_at, :created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta, :crypted_password, :password, :last_logged_in_at]})

  SEARCH_ATTRIBUTES = [:organization_id, :state, :updated_at, :group_ids]
  insta_search do |insta|
    insta.filter_fields = SEARCH_ATTRIBUTES
  end

  insta_realtime do |insta|
    insta.delta_attributes = SEARCH_ATTRIBUTES
    insta.updated_by_field = :updated_by_id
  end
  insta_multi
  
  include URLCleaner
  def before_create
    self.blog_url = clean_url(self.blog_url)
  end
  def before_update
    self.blog_url = clean_url(self.blog_url)
  end
  
  def merge dup
    unless dup.nil? || self == dup
      User.suspended_delta do # Turn off sphinx indexing throughout this process
        User.transaction do
          
          dup.destroy
        end
      end
    end
  end
  
  # In the implementation, you can override this method or alias_method_chain to put it aside and call it as well 
  def merge_associations
    [Audit, Dashboard, Favorite, ModelDelta, RolesUser].each do |aclass|
      aclass.update_all ['user_id = ?', self.id], ['user_id = ?', dup.id]
    end
    
    GroupMember.update_all ['groupable_id = ?', self.id], ['groupable_id = ? and groupable_type = ?', dup.id, User.name]
    GroupMember.update_all ['created_by_id = ?', self.id], ['created_by_id = ?', dup.id]
    GroupMember.update_all ['updated_by_id = ?', self.id], ['updated_by_id = ?', dup.id]
    
    # Kill the primary_user_organization_id for this user
    dup.update_attribute :primary_user_organization_id, nil

    # Delete out duplicate user orgs
    User.connection.execute 'DROP TEMPORARY TABLE IF EXISTS dupe_user_orgs'
    User.connection.execute User.send(:sanitize_sql, ['CREATE TEMPORARY TABLE dupe_user_orgs SELECT organization_id, COUNT(*) tot 
        FROM user_organizations WHERE user_id IN (?) GROUP BY organization_id', [self.id]])
    User.connection.execute User.send(:sanitize_sql, ['DELETE user_organizations.* FROM user_organizations, dupe_user_orgs 
        WHERE user_id = ? AND dupe_user_orgs.organization_id = user_organizations.organization_id', dup.id])
    
    [Note, OrganizationDocument, Organization, RequestDocument, RequestFundingSource, RequestReport, 
        RequestLetter, RequestTransaction, WorkflowEvent, Request, User].each do |aclass|
      aclass.update_all ['created_by_id = ?', self.id], ['created_by_id = ?', dup.id]
      aclass.update_all ['modified_by_id = ?', self.id], ['modified_by_id = ?', dup.id]
      unless aclass == Note || aclass == WorkflowEvent || aclass == RequestDocument || aclass == GroupMember # notes and workflow_events are not lockable
        aclass.update_all 'locked_by_id = null, locked_until = null', ['locked_by_id = ?', dup.id]
      end
    end
    
    # UserOrganization is a bit of an outlier as it has locked_by_id but not created_by_id/modified_by_id
    UserOrganization.update_all 'locked_by_id = null, locked_until = null', ['locked_by_id = ?', dup.id]
    UserOrganization.update_all ['user_id = ?', self.id], ['user_id = ?', dup.id]
    
    
    
    # Need to be sure for our polymorphic relations that we're covered
    Note.update_all ['notable_id = ?', self.id], ['notable_type = ? AND notable_id = ?', 'User', dup.id]
    RequestUser.update_all ['user_id = ?', self.id], ['user_id = ?', dup.id]
    
    Favorite.update_all ['favorable_id = ?', self.id], ['favorable_type = ? AND favorable_id = ?', 'User', dup.id]
    Role.update_all ['authorizable_id = ?', self.id], ['authorizable_type = ? AND authorizable_id = ?', 'User', dup.id]
  end
  
  # TODO ESH: add authentication validation (login/email/password etc)
  insta_utc do |insta|
    insta.time_attributes = [:birth_at]
  end  
end