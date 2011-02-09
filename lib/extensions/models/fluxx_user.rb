module FluxxUser
  include ::URLCleaner
  SEARCH_ATTRIBUTES = [:state, :updated_at, :first_name, :last_name]
  LIQUID_METHODS = [:salutation, :full_name, :first_name, :last_name, :title, :main_phone, :email, :work_phone, :work_fax]  

  def self.included(base)
    base.has_many :user_organizations
    base.has_many :organizations, :through => :user_organizations
    base.belongs_to :personal_geo_country, :class_name => 'GeoCountry', :foreign_key => :personal_geo_country_id
    base.belongs_to :personal_geo_state, :class_name => 'GeoState', :foreign_key => :personal_geo_state_id
    base.belongs_to :primary_user_organization, :class_name => 'UserOrganization', :foreign_key => :primary_user_organization_id
    base.belongs_to :primary_organization, :class_name => 'Organization', :include => :primary_user_organization, :foreign_key => 'organization_id'
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.belongs_to :user_profile
    base.has_many :model_documents, :as => :documentable
    base.has_many :notes, :as => :notable, :conditions => {:deleted_at => nil}
    base.has_many :group_members, :as => :groupable
    base.has_many :groups, :through => :group_members
    base.has_many :role_users
    base.has_many :bank_accounts, :foreign_key => :owner_user_id
    base.acts_as_audited({:full_model_enabled => true, :except => [:activated_at, :created_by_id, :updated_by_id, :updated_by, :created_by, :audits, :role_users, :locked_until, :locked_by_id, :delta, :crypted_password, :password, :last_logged_in_at]})
    base.before_save :preprocess_user
    
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
    
    base.validates_presence_of     :first_name
    base.validates_presence_of     :last_name

    base.validates_length_of       :email,    :within => 6..250, :if => lambda {|user| !user.email.blank? }
    base.validates_uniqueness_of   :email, :if => lambda {|user| !user.email.blank? }

    base.validates_length_of       :login,    :within => 6..40, :if => lambda {|user| !user.login.blank? }
    base.validates_uniqueness_of   :login, :if => lambda {|user| !user.login.blank? }
    
    base.insta_utc do |insta|
      insta.time_attributes = [:birth_at]
    end  
    base.insta_favorite
    
    base.insta_template do |insta|
      insta.entity_name = 'user'
      insta.add_methods [:full_name, :main_phone]
      insta.remove_methods [:id]
    end
    base.liquid_methods *( LIQUID_METHODS )    

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    
    # ESH: hack to rename User to Person
    def model_name
      u = ActiveModel::Name.new User
      u.instance_variable_set '@human', 'Person'
      u
    end
    
    def document_title_name
      'Person'
    end
    
    def employees
      user_profile = UserProfile.where(:name => 'employee').first
      if user_profile
        User.where(:user_profile_id => user_profile.id, :deleted_at => nil, :test_user_flag => false).order('first_name asc, last_name asc').all
      end || []
    end
  end

  module ModelInstanceMethods
    
    def main_phone
      work = self.work_phone
      org = primary_user_organization && primary_user_organization.organization ? primary_user_organization.organization.phone : nil
      mobile = self.personal_mobile
      work || org || mobile
    end
    
    def preprocess_user
      self.login = nil if login == ''
    end
    
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
    def has_role_user? role_name, related_object = nil
      role_user = if related_object
        roles = role_users.where(:name => role_name, :roleable_id => related_object.id, :roleable_type => related_object.class.name).all
        roles = role_users.where(:name => role_name, :roleable_id => related_object.parent_id, :roleable_type => related_object.class.name).all if roles.empty? && related_object.respond_to?('parent_id')
        roles
      else
        role_users.where(:name => role_name)
      end.first
    end
    
    # Add a role if none exists; if related_object is a class, generated a role_name that includes the class
    def has_role! role_name, related_object = nil, remove_role=false
      role = if related_object.is_a? Class
        has_role_for_object? role_name, related_object
      elsif related_object.is_a? String
        has_role_for_object? role_name, related_object
      else
        has_role?(role_name, related_object)
      end
      if remove_role
        role.destroy
      else
        if role
          role
        else
          role = if related_object.is_a? Class
            add_role "#{role_name}_#{class_perm_name related_object}"
          elsif related_object.is_a? String
            add_role "#{role_name}_#{related_object.to_s}"
          else
            add_role role_name, related_object
          end
        end
      end
    end
    
    def clear_role role_name, related_object = nil
      has_role! role_name, related_object, true
    end
    
    # Check to see if this users profile includes the role_name
    def user_profile_include? role_name
      if user_profile
        user_profile.has_rule? role_name
      end
    end
    
    # Check for either a simple role or a profile rule for the role associated with this user
    # always_return_object says that if a user_profile_rule is found (and not a role_user), return the rule that was found.  This is because sometimes a rule will be present and be marked not allowed
    def has_role? role_name, related_object = nil, always_return_object=false
      user_profile_role = self.user_profile_include?(role_name) # related object doesn't matter for user_profile_roles
      has_role_user?(role_name, related_object) || (always_return_object ? user_profile_role : (user_profile_role && user_profile_role.allowed?))
    end
    
    # Calculate the tableized name of a model_class
    def class_perm_name model_class
      model_class.name.tableize.singularize.downcase
    end
    
    def user_related_to_model? model
      (model.respond_to?(:relates_to_user?) && model.relates_to_user?(self))
    end
    
    def is_admin?
      self.has_role?('admin')
    end
    
    # role_name: name of role to check for this user
    # model: accept either a class, string or model
    def has_role_for_object? role_name, model
      cur_model = if model.is_a? Class
        model
      elsif model.is_a? String
        model
      else
        model.class
      end
      role_found = false
      while cur_model && !role_found
        role_found = if cur_model.is_a? Class
          has_role?("#{role_name}_#{class_perm_name(cur_model)}", nil, true)
        else
          has_role?("#{role_name}_#{cur_model.to_s}", nil, true)
        end
        if cur_model.is_a? Class
          cur_model = cur_model.superclass
          cur_model = nil if cur_model == ActiveRecord::Base || cur_model == Object
        else
          cur_model = nil
        end
      end

      if role_found && role_found.is_a?(UserProfileRule)
        role_found.allowed
      elsif role_found
        role_found
      elsif ['create', 'update', 'delete', 'view', 'listview'].include? role_name.to_s
        has_role?("create_all")
      else
        role_found
      end
    end

    def has_create_for_own_model? model_class
      has_role_for_object?("create_own", model_class)
    end
    
    def has_create_for_model? model_class
      is_admin? || has_role_for_object?("create", model_class)
    end
    
    def has_update_for_own_model? model
      has_role_for_object?("update_own", model) && user_related_to_model?(model)
    end

    def has_update_for_model? model_class
      is_admin? || has_role_for_object?("update", model_class)
    end
    
    def has_delete_for_own_model? model
      has_role_for_object?("delete_own", model) && user_related_to_model?(model)
    end

    def has_delete_for_model? model_class
      is_admin? || has_role_for_object?("delete", model_class)
    end
    
    def has_listview_for_model? model_class
      is_admin? || has_role_for_object?("listview", model_class)
    end
    
    def has_view_for_own_model? model
      has_role_for_object?("view_own", model) && user_related_to_model?(model)
    end

    def has_view_for_model? model_class
      is_admin? || has_role_for_object?("view", model_class)
    end
    
    def full_name
      [first_name, last_name].join ' '
    end
    
    def to_s
      full_name
    end
  end
end
