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
    base.has_many :notes, :as => :notable, :conditions => {:deleted_at => nil}
    base.has_many :group_members, :as => :groupable
    base.has_many :groups, :through => :group_members
    base.has_many :favorites, :as => :favorable
    base.acts_as_audited({:full_model_enabled => true, :except => [:activated_at, :created_by_id, :updated_by_id, :locked_until, :locked_by_id, :delta, :crypted_password, :password, :last_logged_in_at]})
    
    # Allow users to update fields in user
    User.column_names.reject {|name| name.to_s == 'id'}.each do |name|
      base.attr_accessible name.to_sym
    end

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
      [Audit, ClientStore, Favorite, RealtimeUpdate].each do |aclass|
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
      self.roles = self.roles | dup.roles
    end
    
    def roles= roles_array
      return false unless roles_array && roles_array.is_a?(Array)
      self.roles_text = roles_array.to_yaml 
    end

    def roles
      (roles_text ? roles_text.de_yaml : nil) || []
    end
    
    # The role names may be very descriptive and thus may relate to specific model objects
    # make sure you reload the user to prevent somebody else from overwriting a role
    def add_role new_role
      User.transaction do
        up_to_date_user = User.find self.id
        roles_array = up_to_date_user.roles
        unless roles_array.include? new_role
          roles_array << new_role
          up_to_date_user.roles = roles_array
          if up_to_date_user.save
            self.roles = roles_array
          end
        end
      end
    end
    
    # remove a role; make sure you reload the user to prevent somebody else from overwriting a role
    def remove_role old_role
      User.transaction do
        up_to_date_user = User.find self.id
        roles_array = up_to_date_user.roles
        if roles_array.include? old_role
          roles_array.delete old_role
          up_to_date_user.roles = roles_array
          if up_to_date_user.save
            self.roles = roles_array
          end
        else
          true
        end
      end
    end
    
    def has_role? expected_roles
      return false unless expected_roles
      expected_roles = [expected_roles] unless expected_roles.is_a?(Array)
      !(expected_roles.select {|r| self.roles.include? r }).empty?
    end
    
    def full_name
      [first_name, last_name].join ' '
    end
    
    def to_s
      full_name
    end
  end
end