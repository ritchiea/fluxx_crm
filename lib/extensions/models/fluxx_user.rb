module FluxxUser
  include ::URLCleaner
  SEARCH_ATTRIBUTES = [:state, :updated_at, :first_name, :last_name]

  def self.included(base)
    base.has_many :user_organizations, :conditions => 'user_organizations.deleted_at IS NULL'
    base.has_many :organizations, :through => :user_organizations
    base.belongs_to :personal_geo_country, :class_name => 'GeoCountry', :foreign_key => :personal_geo_state_id
    base.belongs_to :personal_geo_state, :class_name => 'GeoState', :foreign_key => :personal_geo_state_id
    base.belongs_to :primary_user_organization, :class_name => 'UserOrganization', :foreign_key => :primary_user_organization_id
    base.belongs_to :primary_organization, :class_name => 'Organization', :include => :primary_user_organization, :foreign_key => 'organization_id'
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.has_many :model_documents, :as => :documentable
    base.has_many :notes, :as => :notable, :conditions => {:deleted_at => nil}
    base.has_many :group_members, :as => :groupable
    base.has_many :groups, :through => :group_members
    base.has_many :role_users
    base.acts_as_audited({:full_model_enabled => true, :except => [:activated_at, :created_by_id, :updated_by_id, :locked_until, :locked_by_id, :delta, :crypted_password, :password, :last_logged_in_at], :protect => true})
    
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
    end

    base.insta_realtime do |insta|
      insta.delta_attributes = SEARCH_ATTRIBUTES
      insta.updated_by_field = :updated_by_id
    end
    base.insta_multi
    base.insta_export
    base.insta_lock
    # TODO ESH: add authentication validation (login/email/password etc)
    base.insta_utc do |insta|
      insta.time_attributes = [:birth_at]
    end  
    base.insta_favorite

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def before_create
      self.blog_url = clean_url(self.blog_url)
    end
    def before_update
      self.blog_url = clean_url(self.blog_url)
    end
    def merge dup
      unless dup.nil? || self == dup
        User.transaction do
          merge_associations dup
          dup.destroy
        end
      end
    end

    # In the implementation, you can override this method or alias_method_chain to put it aside and call it as well 
    def merge_associations dup
      my_role_users = RoleUser.where(:user_id => self.id).all
      RoleUser.where(:user_id => dup.id).all.each do |ru|
        existing_ru = my_role_users.select {|mru| mru.name == ru.name && mru.roleable == ru.roleable}
        ru.destroy unless existing_ru.empty?
      end
      
      [Audit, ClientStore, Favorite, RealtimeUpdate, RoleUser].each do |aclass|
        aclass.update_all ['user_id = ?', self.id], ['user_id = ?', dup.id]
      end

      GroupMember.update_all ['groupable_id = ?', self.id], ['groupable_id = ? and groupable_type = ?', dup.id, User.name]
      GroupMember.update_all ['created_by_id = ?', self.id], ['created_by_id = ?', dup.id]
      GroupMember.update_all ['updated_by_id = ?', self.id], ['updated_by_id = ?', dup.id]

      # Kill the primary_user_organization_id for this user
      dup.update_attribute :primary_user_organization_id, nil

      User.connection.execute 'DROP TABLE IF EXISTS dupe_user_orgs'
      User.connection.execute User.send(:sanitize_sql, ['CREATE TEMPORARY TABLE dupe_user_orgs AS SELECT organization_id, COUNT(*) tot 
          FROM user_organizations WHERE user_id IN (?) GROUP BY organization_id', [self.id]])
      User.connection.execute User.send(:sanitize_sql, ['DELETE FROM user_organizations 
          WHERE user_id = ? AND user_organizations.organization_id IN (select organization_id from dupe_user_orgs)', dup.id])
      UserOrganization.update_all ['user_id = ?', self.id], ['user_id = ?', dup.id] # Now take care of the rest of the user orgs

      [UserOrganization, Note, Organization, User, ModelDocument, Group].each do |aclass|
        aclass.update_all ['created_by_id = ?', self.id], ['created_by_id = ?', dup.id]
        aclass.update_all ['updated_by_id = ?', self.id], ['updated_by_id = ?', dup.id]
        unless aclass == Note || aclass == GroupMember || aclass == Group # not lockable
          aclass.update_all 'locked_by_id = null, locked_until = null', ['locked_by_id = ?', dup.id]
        end
      end

      # Need to be sure for our polymorphic relations that we're covered
      Note.update_all ['notable_id = ?', self.id], ['notable_type = ? AND notable_id = ?', 'User', dup.id]

      Favorite.update_all ['favorable_id = ?', self.id], ['favorable_type = ? AND favorable_id = ?', 'User', dup.id]
    end
    
    def add_role role_name, related_object = nil
      role_users.create :name => role_name, :roleable => related_object
    end
    
    def remove_role role_name, related_object = nil
      role_user = has_role? role_name, related_object
      role_user.destroy if role_user
    end
    
    # Includes a device to map related_objects to their parents, so if a user does not have a relationship to the related_object, they may have one to the parent
    def has_role? role_name, related_object = nil
      role_user = if related_object
        roles = role_users.where(:name => role_name, :roleable_id => related_object.id, :roleable_type => related_object.class.name).all
        roles = role_users.where(:name => role_name, :roleable_id => related_object.parent_id, :roleable_type => related_object.class.name).all if roles.empty? && related_object.respond_to?('parent_id')
        roles
      else
        role_users.where(:name => role_name)
      end.first
    end
    
    def has_role! role_name, related_object = nil
      role = has_role?(role_name, related_object)
      if role
        role
      else
        add_role role_name, related_object
      end
    end
    
    def full_name
      [first_name, last_name].join ' '
    end
    
    def to_s
      full_name
    end
  end
end
