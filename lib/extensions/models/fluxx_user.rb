require 'net/ldap'
module FluxxUser
  include ::URLCleaner
  SEARCH_ATTRIBUTES = [:state, :updated_at, :first_name, :last_name, :user_profile_id]

  def self.included(base)
    base.has_many :user_organizations
    base.has_many :organizations, :through => :user_organizations, :conditions => {:organizations => {:deleted_at => nil}}
    base.belongs_to :personal_geo_country, :class_name => 'GeoCountry', :foreign_key => :personal_geo_country_id
    base.belongs_to :personal_geo_state, :class_name => 'GeoState', :foreign_key => :personal_geo_state_id
    base.belongs_to :primary_user_organization, :class_name => 'UserOrganization', :foreign_key => :primary_user_organization_id
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.belongs_to :user_profile
    if User.columns.map(&:name).include?('client_id')
      base.belongs_to :client 
    else
      base.send :attr_accessor, :client
    end
    base.has_many :model_documents, :as => :documentable
    base.has_many :notes, :as => :notable, :conditions => {:deleted_at => nil}
    base.has_many :group_members, :as => :groupable
    base.has_many :groups, :through => :group_members
    base.has_many :role_users
    base.has_many :roles, :through => :role_users
    base.has_many :user_permissions
    base.has_many :bank_accounts, :foreign_key => :owner_user_id
    base.has_many :work_tasks, :foreign_key => :assigned_user_id, :conditions => {:deleted_at => nil}
    
    base.acts_as_audited({:full_model_enabled => false, :except => [:activated_at, :created_by_id, :updated_by_id, :updated_by, :created_by, :audits, :role_users, :locked_until, :locked_by_id, :delta, :crypted_password, :password, :last_logged_in_at]})
    base.before_save :preprocess_user
    base.after_save :email_login_pass_callback
    base.send :attr_accessor, :temp_organization_title
    base.send :attr_accessor, :temp_organization_id

    base.insta_formbuilder
    
    base.acts_as_authentic do |c|
      # c.my_config_option = my_value # for available options see documentation in: Authlogic::ActsAsAuthentic
      c.act_like_restful_authentication = true
      c.validate_login_field=false
      c.validate_password_field=false
      c.validate_email_field=false
    end # block optional
    

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
    
    base.insta_json do |insta|
      insta.add_method 'primary_org_name'
      insta.add_method 'primary_org_title'
      insta.add_only 'first_name'
      insta.add_only 'last_name'
      insta.copy_style :simple, :detailed
      insta.add_method 'related_organizations', :detailed
      insta.add_method 'related_work_tasks', :detailed
    end
    
    base.validates_presence_of     :first_name
    base.validates_presence_of     :last_name

    base.validates_length_of       :email,    :within => 6..250, :if => lambda {|user| !user.email.blank? }
    base.validates_uniqueness_of   :email, :if => lambda {|user| !user.email.blank? }, :scope => [:deleted_at]

    base.validates_length_of       :login,    :within => 6..40, :if => lambda {|user| !user.login.blank? }
    base.validates_uniqueness_of   :login, :if => lambda {|user| !user.login.blank? }, :scope => [:deleted_at]
    
    base.insta_utc do |insta|
      insta.time_attributes = [:birth_at]
    end  
    base.insta_favorite
    
    base.insta_template do |insta|
      insta.entity_name = 'user'
      insta.add_methods [:full_name, :main_phone, :salutation, :prefix, :full_name, :first_name, :last_name, :title, :main_phone, :email, :work_phone, :work_fax, :primary_user_organization, :personal_street_address, :personal_street_address2, :personal_city, :personal_state_name, :personal_postal_code, :personal_country_name, :created_by, :updated_by]
      insta.remove_methods [:id]
    end
    
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
    
    def users_with_profile profile_name
      if profile_name && (user_profile = UserProfile.all_user_profile_map_by_name[profile_name])
        User.where(:user_profile_id => user_profile.id, :deleted_at => nil, :test_user_flag => false).order('first_name asc, last_name asc').all
      end || []
    end
    
    # Tries to find a User first by looking into the database and then by creating a User if there's an LDAP entry for the given login
    def find_or_create_from_ldap(login)
      find_by_login(login) || create_from_ldap_if_valid(login)
    end  

    ######################################### LDAP
    # Creates a User record in the database if there is an entry in LDAP with the given login
    def create_from_ldap_if_valid(login)
      return nil unless Fluxx.config(:ldap_enabled) == "1"
      begin
        ldap_user = User.ldap_find(login)
        if ldap_user
          return User.create_or_update_user_from_ldap_entry(login, ldap_user)
        end
      rescue Exception => e
        logger.error "Unable to do an ldap login, error=#{e.inspect} trace: #{e.backtrace.inspect}"
        HoptoadNotifier.notify(:error_message => "Unable to do an ldap login, error=#{e.inspect} trace: #{e.backtrace.inspect}")
      end
      nil
    end

    def ldap_find(login)
      return nil unless Fluxx.config(:ldap_enabled) == "1"
      # see http://net-ldap.rubyforge.org/Net/LDAP.html
      ldap = Net::LDAP.new
      ldap.host = LDAP_CONFIG[:host]
      ldap.port = LDAP_CONFIG[:port]
      ldap.base = LDAP_CONFIG[:base]
      ldap.encryption LDAP_CONFIG[:encryption] if LDAP_CONFIG[:encryption]
      ldap.auth LDAP_CONFIG[:bind_dn], LDAP_CONFIG[:password]
      filter = Net::LDAP::Filter.eq(LDAP_CONFIG[:login_attr], login) 
      results = ldap.search(:filter => filter) rescue []
      results.each do |entry|
        logger.info "FOUND IN LDAP:  #{login}"
        return entry
      end
      logger.info { "NOT FOUND IN LDAP:  #{login}" }
      nil
    end    
    
    def create_or_update_user_from_ldap_entry(login, entry)
      user = User.find_by_login login
      user = User.new(:login => login) unless user
      logger.info "#{user.new_record? ? 'Creating' : 'Updating'} user from ldap entry: #{login}"
      user.first_name = entry[LDAP_CONFIG[:first_name_attr]].first
      user.last_name  = entry[LDAP_CONFIG[:last_name_attr]].first
      user.email      = entry[LDAP_CONFIG[:email_attr]].first
      user.user_profile = UserProfile.find_by_name 'employee' if user.new_record?
      user.save
      logger.info { "user.errors = #{user.errors.inspect}" }
      return user
    end
  end

  module ModelInstanceMethods
    
    # maps our user object to standard LDAP schemas
    def to_ldap_entry
      # id, login, first_name, last_name, email, personal_email, salutation, prefix, middle_initial, 
      # personal_phone, personal_mobile, personal_fax, 
      # personal_street_address, personal_street_address2, personal_city, personal_geo_state_id, personal_geo_country_id, personal_postal_code, 
      # work_phone, work_fax, other_contact, assistant_name, assistant_phone, assistant_email, 
      # blog_url, twitter_url, birth_at, user_salutation, 
      # primary_user_organization_id, time_zone, linkedin_url, facebook_url, first_name_foreign_language, middle_name_foreign_language, last_name_foreign_language
      { 
        # top
        "objectclass" =>  [ "top", "person", "organizationalPerson", "inetOrgPerson", "mozillaOrgPerson"],
        
        # person
        # MAY ( description $ seeAlso $ telephoneNumber $ userPassword ) 
        # MUST ( cn $ sn )
        "sn" => [last_name],
        "cn" => [full_name],
        "telephoneNumber" => [work_phone],
        # "description" => ["description"],
        
        # organizationalPerson
        # MAY ( destinationIndicator $ facsimileTelephoneNumber $ internationaliSDNNumber $ l $ ou $ physicalDeliveryOfficeName $ postOfficeBox $ postalAddress $ postalCode $ preferredDeliveryMethod $ registeredAddress $ st $ street $ telephoneNumber $ teletexTerminalIdentifier $ telexNumber $ title $ x121Address )
        "ou" => [primary_user_organization.present? ? primary_user_organization.department : ""],
        "facsimileTelephoneNumber" => [work_fax],
        # "facsimileTelephoneNumber" => [personal_fax],
        "title" => [title],
        "street" => [ primary_organization ? primary_organization.street_address : nil],
        "street2" => [primary_organization ? primary_organization.street_address2 : nil], #?? TODO
        "l" => [primary_organization ? primary_organization.city : nil],
        "st" => [primary_organization ? primary_organization.state_name : nil],
        "c" => [primary_organization ? primary_organization.country_name : nil],
        # "postalAddress" => ["postalAddress"], # ??
        "postalCode" => [primary_organization ? primary_organization.postal_code : nil],
        
        # inetOrgPerson
        # MAY ( audio $ businessCategory $ carLicense $ departmentNumber $ displayName $ employeeNumber $ employeeType $ givenName $ homePhone $ homePostalAddress $ initials $ jpegPhoto $ labeledURI $ mail $ manager $ mobile $ o $ pager $ photo $ preferredLanguage $ roomNumber $ secretary $ uid $ userCertificate $ userPKCS12 $ userSMIMECertificate $ x500uniqueIdentifier )
        "o" => [primary_org_name],
        "givenName" => [first_name],
        "homePhone" => [personal_phone],
        "homePostalAddress" => [full_personal_address],        
        "mail" => [email],
        "mobile" => [personal_mobile],
        # "pager" => ["pager"],
        "secretary" => [assistant_name],
        "uid" => [id] # make sure dn is unique
        
        # mozillaOrgPerson
        # MAY ( sn $ givenName $ cn $ displayName $ mozillaNickname $ title $ telephoneNumber $ facsimileTelephoneNumber $ mobile $ pager $ homePhone $ street $ postalCode $ mozillaPostalAddress2 $ mozillaHomeStreet $ mozillaHomePostalAddress2 $ l $ mozillaHomeLocalityName $ st $ mozillaHomeState $ mozillaHomePostalCode $ c $ mozillaHomeCountryName $ co $ mozillaHomeFriendlyCountryName $  ou $ o $ mail $ mozillaSecondEmail $ mozillaUseHtmlMail $ nsAIMid $ mozillaHomeUrl $ mozillaWorkUrl $ description $ mozillaCustom1 $ mozillaCustom2 $ mozillaCustom3 $ mozillaCustom4 )        
        # "mozillaPostalAddress2" => ["mozillaPostalAddress2"],
        # "mozillaHomeStreet" => ["mozillaHomeStreet"],
        # "mozillaHomePostalAddress2" => ["mozillaHomePostalAddress2"],
        # "mozillaHomeLocalityName" => ["mozillaHomeLocalityName"],
        # "mozillaHomeState" => ["mozillaHomeState"],
        # "mozillaHomePostalCode" => ["mozillaHomePostalCode"],
        # "mozillaHomeCountryName" => ["mozillaHomeCountryName"]
        # "mozillaHomeFriendlyCountryName" => ["mozillaHomeFriendlyCountryName"],
        # "mozillaSecondEmail" => ["mozillaSecondEmail"],
        # "mozillaUseHtmlMail" => ["mozillaUseHtmlMail"],
        # "nsAIMid" => ["nsAIMid"],
        # "mozillaHomeUrl" => ["mozillaHomeUrl"],
        # "mozillaWorkUrl" => ["mozillaWorkUrl"],
        # "mozillaCustom1" => ["mozillaCustom1"],
        # "mozillaCustom2" => ["mozillaCustom2"],
        # "mozillaCustom3" => ["mozillaCustom3"],
        # "mozillaCustom4" => ["mozillaCustom4"]
      }
    end
    
    def full_personal_address
      str = []
      str << personal_street_address if personal_street_address.present?
      str << personal_street_address2 if personal_street_address2.present?
      str << personal_city if personal_city.present?
      state_str = []
      state_str << personal_state_name if personal_state_name.present?
      state_str << personal_postal_code if personal_postal_code.present?
      state_str << personal_country_name if personal_country_name.present?
      str << state_str.join(' ') unless state_str.empty?
      str.compact.join(', ')
    end
    
    def login=(value)
      write_attribute :login, (value.blank? ? nil : value)
    end

    def email=(value)
      write_attribute :email, (value.blank? ? nil : value)
    end
    
    def main_phone
      work = self.work_phone
      org = primary_user_organization && primary_user_organization.organization ? primary_user_organization.organization.phone : nil
      mobile = self.personal_mobile
      work || org || mobile
    end

    def main_fax
      work = self.work_fax
      org = primary_user_organization && primary_user_organization.organization ? primary_user_organization.organization.fax : nil
      work || org
    end
    
    def preprocess_user
      self.login = nil if login == ''
    end
    
    def email_login_pass_callback
      if password && !changed_attributes['password'] && login && !changed_attributes['login'] && email
        # The user has never had a login/password assigned before, let's send them an email with the information
        begin
          UserMailer.new_user(self).deliver 
        rescue Exception => e
          ActiveRecord::Base.logger.error "exception sending a new password email #{e.inspect}, #{e.backtrace.inspect}, email=#{email}"
        end
      end
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
      my_role_users = RoleUser.joins(:role).where(:user_id => self.id).all
      RoleUser.joins(:role).where(:user_id => dup.id).all.each do |ru|
        existing_ru = my_role_users.select {|mru| mru.role.name == ru.role.name && mru.roleable_id == ru.roleable_id}
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

      User.connection.execute 'DROP TEMPORARY TABLE IF EXISTS dupe_user_orgs'
      User.connection.execute User.send(:sanitize_sql, ['CREATE TEMPORARY TABLE dupe_user_orgs AS SELECT organization_id, COUNT(*) tot 
          FROM user_organizations WHERE user_id IN (?) GROUP BY organization_id', [self.id]])
      User.connection.execute User.send(:sanitize_sql, ['DELETE FROM user_organizations 
          WHERE user_id = ? AND user_organizations.organization_id IN (select organization_id from dupe_user_orgs)', dup.id])
      UserOrganization.update_all ['user_id = ?', self.id], ['user_id = ?', dup.id] # Now take care of the rest of the user orgs

      ActiveRecord::Base.connection.execute("SELECT table_name, column_name FROM information_schema.KEY_COLUMN_USAGE where TABLE_SCHEMA='#{ActiveRecord::Base.connection.current_database}' AND REFERENCED_TABLE_NAME='#{self.class.rationalized_table_name}' and REFERENCED_COLUMN_NAME = 'id'").each(:cache_rows => false, :symbolize_keys => true, :as => :hash) do |row|
        klass = self.class.rationalize_klass_from_name row[:table_name]
        if klass
          klass.update_all ["#{row[:column_name]} = ?", id], ["#{row[:column_name]} = ?", dup.id]
        end
      end

      # Need to be sure for our polymorphic relations that we're covered
      Note.update_all ['notable_id = ?', self.id], ['notable_type = ? AND notable_id = ?', 'User', dup.id]
      ModelDocument.update_all ['documentable_id = ?', self.id], ['documentable_type = ? AND documentable_id = ?', 'User', dup.id]
      Favorite.update_all ['favorable_id = ?', self.id], ['favorable_type = ? AND favorable_id = ?', 'User', dup.id]
    end
    
    ######################################### ROLES
    def add_role role_name, related_object = nil
      role = if related_object
        related_object_class = related_object.is_a?(Class) ? related_object : related_object.class
        Role.where(:name => role_name, :roleable_type => related_object_class.name).first || Role.create(:name => role_name, :roleable_type => related_object_class.name)
      else
        Role.where(:name => role_name).first || Role.create(:name => role_name)
      end
      if related_object
        role_users.create :role_id => role.id, :roleable_id => related_object.id if role
      else
        role_users.create :role_id => role.id if role
      end
    end
    
    def remove_role role_name, related_object = nil
      role_user = has_role? role_name, related_object
      role_user.destroy if role_user
    end
    
    def has_related_role? related_klass
      is_admin? || role_users.joins(:role).where(:roles => {:roleable_type => related_klass.name}).exists?
    end
    
    # Includes a device to map related_objects to their parents, so if a user does not have a relationship to the related_object, they may have one to the parent
    def has_role_user? role_name, related_object = nil
      return true if is_admin?
      if related_object
        roles = role_users.joins(:role).where(:roleable_id => related_object.id, :roles => {:roleable_type => related_object.class.name, :name => role_name}).all
        roles = role_users.joins(:role).where(:roleable_id => related_object.parent_id, :roles => {:roleable_type => related_object.class.name, :name => role_name}).all if roles.empty? && related_object.respond_to?('parent_id')
        roles
      else
        role_users.joins(:role).where(:roles => {:name => role_name})
      end.first
    end
    
    # Add a role if none exists; if related_object is a class, generated a role_name that includes the class
    def has_role! role_name, related_object = nil, remove_role=false
      role = has_role?(role_name, related_object)

      if remove_role
        role.destroy
      else
        if role
          role
        else
          role = add_role role_name, related_object
        end
      end
    end
    
    def clear_role role_name, related_object = nil
      has_role! role_name, related_object, true
    end
    
    # Check for a role associated with this user
    def has_role? role_name, related_object = nil
      return true if is_admin?
      has_role_user?(role_name, related_object)
    end

######################################### PERMISSIONS

    def add_permission permission_name, related_object = nil
      perm = if related_object
        user_permissions.create :name => permission_name, :model_type => derive_class_name(related_object) if related_object
      else
        user_permissions.create :name => permission_name
      end
      @local_cached_permissions = nil
      perm
    end

    def remove_permission permission_name, related_object = nil
      user_permission = has_permission? permission_name, related_object
      result = user_permission.destroy if user_permission
      @local_cached_permissions = nil
      result
    end
    
    # Includes a device to map related_objects to their parents, so if a user does not have a relationship to the related_object, they may have one to the parent
    def has_user_permission? permission_name, related_object = nil
      # Load up all user_permissions once per user object; only grab required fields
      @local_cached_permissions ||= user_permissions.select([:model_type, :name, :id]).all
      
      if related_object
        related_class_name = derive_class_name(related_object)
        @local_cached_permissions.select{|perm| related_class_name == perm.model_type && permission_name == perm.name}
      else
        @local_cached_permissions.select{|perm| permission_name == perm.name}
      end.first
    end

    # Add a permission if none exists
    def has_permission! permission_name, related_object = nil, remove_permission=false
      permission = has_permission? permission_name, derive_class_name(related_object)
      result = if remove_permission
        permission.destroy
      else
        if permission
          permission
        else
          permission = add_permission permission_name, related_object
        end
      end
      @local_cached_permissions = nil
      result
    end
    
    def derive_class_name related_object
      if related_object.is_a? Class
        related_object.name
      elsif related_object.is_a? String
        related_object
      elsif related_object
        related_object.class.name
      end
    end

    def clear_permission permission_name, related_object = nil
      result = has_permission! permission_name, related_object, true
      @local_cached_permissions = nil
      result
    end

    # Check for either a simple permission or a profile rule for the permission associated with this user
    # always_return_object says that if a user_profile_rule is found (and not a user_permission), return the rule that was found.  This is because sometimes a rule will be present and be marked not allowed
    def has_permission? permission_name, related_object = nil, always_return_object=false
      user_profile_permission = self.user_profile_include?(permission_name, related_object)
      has_user_permission?(permission_name, related_object) || (always_return_object ? user_profile_permission : (user_profile_permission && user_profile_permission.allowed?))
    end
    
    # Check to see if this users profile includes the permission_name
    def user_profile_include? permission_name, related_object = nil
      if user_profile_id && UserProfile.all_user_profile_map[user_profile_id]
        UserProfile.all_user_profile_map[user_profile_id].has_rule?(permission_name, derive_class_name(related_object))
      end
    end
    
    def user_related_to_model? model
      (model.respond_to?(:relates_to_user?) && model.relates_to_user?(self))
    end
    
    def user_related_to_class? model_class, options={}
      (model_class.respond_to?(:relates_to_class?) && model_class.relates_to_class?(self, options))
    end

    def is_admin?
      self.has_permission?('admin') || is_super_admin?
    end
    
    def is_super_admin?
      self.has_permission?('super_admin')
    end
    
    # permission_name: name of permission to check for this user
    # model: accept either a class, string or model
    def has_permission_for_object? permission_name, model
      cur_model = if model.is_a? Class
        model
      elsif model.is_a? String
        model
      else
        model.class
      end
      permission_found = false
      while cur_model && !permission_found
        permission_found = has_permission?(permission_name, cur_model, true)
        if cur_model.is_a? Class
          cur_model = cur_model.superclass
          cur_model = nil if cur_model == ActiveRecord::Base || cur_model == Object
        else
          cur_model = nil
        end
      end

      if permission_found && permission_found.is_a?(UserProfileRule)
        permission_found.allowed
      elsif permission_found
        permission_found
      elsif ['create', 'update', 'delete', 'view', 'listview'].include? permission_name.to_s
        has_permission?("create_all")
      else
        permission_found
      end
    end

    def has_create_for_own_model? model_class
      has_permission_for_object?("create_own", model_class)
    end
    
    def has_create_for_model? model_class
      is_admin? || has_permission_for_object?("create", model_class) || has_create_for_own_model?(model_class)
    end
    
    def has_update_for_own_model? model
      has_permission_for_object?("update_own", model) && user_related_to_model?(model)
    end

    def has_update_for_model? model_class
      is_admin? || has_permission_for_object?("update", model_class) || has_update_for_own_model?(model_class)
    end
    
    def has_delete_for_own_model? model
      has_permission_for_object?("delete_own", model) && user_related_to_model?(model)
    end

    def has_delete_for_model? model_class
      is_admin? || has_permission_for_object?("delete", model_class)  || has_delete_for_own_model?(model_class)
    end
    
    def has_listview_for_model? model_class
      is_admin? || has_permission_for_object?("listview", model_class)
    end

    def has_listview_for_own_model? model_class, options={}
      is_admin? || (has_permission_for_object?("listview_own", model_class) && user_related_to_class?(model_class, options))
    end
    
    def has_view_for_own_model? model
      has_permission_for_object?("view_own", model) && user_related_to_model?(model)
    end

    def has_view_for_model? model_class
      is_admin? || has_permission_for_object?("view", model_class) || has_view_for_own_model?(model_class)
    end
    
    def has_named_user_profile? name
      user_profile = UserProfile.all_user_profile_map_by_name[name]
      user_profile && self.user_profile_id == user_profile.id
    end
    
    def is_employee?
      has_named_user_profile? 'Employee'
    end

    def is_board_member?
      has_named_user_profile? 'Board'
    end

    def is_consultant?
      has_named_user_profile? 'Consultant'
    end

    def full_name
      [first_name, last_name].join ' '
    end
    
    def to_s
      full_name
    end
    
    def to_liquid
      {"email" => email}
    end
    
    def title
      primary_user_organization ? primary_user_organization.title : ''
    end
    
    def primary_organization
      primary_user_organization.organization if primary_user_organization
    end
    
    def mailer_email
      "#{full_name} <#{email}>"
    end
    
    def related_organizations limit_amount=50
      organizations.order('name asc').limit(limit_amount)
    end
    
    def related_work_tasks limit_amount=50
      work_tasks.order('due_at desc').limit(limit_amount)
    end
    
    
    def personal_state_name
      personal_geo_state.name if personal_geo_state
    end
    
    def personal_country_name
      personal_geo_country.name if personal_geo_country
    end
    
    def primary_org_name
      primary_organization.name if primary_organization
    end
    def primary_org_title
      primary_user_organization.title if primary_user_organization
    end
    
    def is_external_user?
      (self.respond_to?(:is_portal_user?) ? self.is_portal_user? : false)
    end
    
    
    ######################################### AUTHLOGIC / LDAP
    
    # check ldap credentials(and sync info), or db credentials(normal authlogic pw check)
    def valid_credentials?(password)
      saml_authenticate?(password) || ldap_authenticate?(password) || valid_password?(password)
    end

    def ldap_authenticate?(password)
      return false unless Fluxx.config(:ldap_enabled) == "1"
      return false unless login.present?
      
      ldap = Net::LDAP.new
      ldap.host = LDAP_CONFIG[:host]
      ldap.port = LDAP_CONFIG[:port]
      ldap.base = LDAP_CONFIG[:base]
      ldap.encryption LDAP_CONFIG[:encryption] if LDAP_CONFIG[:encryption]
      ldap.auth LDAP_CONFIG[:bind_dn], LDAP_CONFIG[:password]
      filter = Net::LDAP::Filter.eq(LDAP_CONFIG[:login_attr], login) 
      begin
        result = ldap.bind_as(:filter => filter, :password => password)
        if result
          logger.info "LDAP Authentication SUCCESSFUL for: #{login}"
          User.create_or_update_user_from_ldap_entry(login, result.first)
          return true
        else
          logger.info "LDAP Authentication FAILED for: #{login}"
        end    
      rescue Exception => e
      end
      false
    end
    
    # Save a saml token and return the generated token
    def saml_store
      saml_name = generate_saml_name
      token = generate_saml_token
      Rails.cache.write(saml_name, token)
      token
    end
    
    # Check to see if the user passed in a saml token instead of a password
    def saml_authenticate?(password)
      saml_name = generate_saml_name
      saml_token = Rails.cache.read(saml_name)
      if saml_token 
        Rails.cache.delete(saml_name)
        token_parts = saml_token.split '_'
        if token_parts.size == 3
          saml_date = token_parts[1].to_i rescue nil
          saml_date > (Time.now - 5.minute).utc.to_i && saml_token == password
        end
      end
    end
    
    def send_forgot_password! controller
      # deactivate!
      reset_perishable_token!
      reset_url = controller.send(:reset_password_url, self.perishable_token)
      UserMailer.forgot_password(self, reset_url).deliver 
    end
    
    LOWER_UPPER_ALPHA_NUMERIC_WITHOUT_O = ("a".."z").to_a + (("A".."Z").to_a - ["O"]) + ("1".."9").to_a
    def generate_random_password len=8
      newpass = ""
      1.upto(len) { |i| newpass << LOWER_UPPER_ALPHA_NUMERIC_WITHOUT_O[rand(LOWER_UPPER_ALPHA_NUMERIC_WITHOUT_O.size-1)] }
      self.password_confirmation = self.password = newpass
    end
    
    # Try the user's first and last names.  If taken, add successively randomly incrementing numbers up to 5000
    def generate_unique_login
      if login
        login
      else
        test_login = "#{first_name}_#{"#{middle_initial}_" if middle_initial}#{last_name}"
        found_login = nil
        counter = 0
        while !found_login && counter < 5000
          cur_login = if counter > 0
            "#{test_login}#{counter}"
          else
            test_login
          end
          if User.where(:login => cur_login).count == 0
            found_login = cur_login
          else
            counter += rand(30)
          end
        end
        self.login = found_login.downcase if found_login
      end
    end
    
    private
    def generate_saml_name
      saml_name = "Authlogic_SAML_Token_#{login}"
    end
    
    def generate_saml_token
      token = "#{ActiveSupport::SecureRandom.hex(15)}_#{Time.now.utc.to_i}_#{Digest::MD5.hexdigest(self.login)}"
    end
  end
end