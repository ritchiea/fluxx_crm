module FluxxOrganization
  include ::URLCleaner
  SEARCH_ATTRIBUTES = [:state, :created_at, :updated_at, :name, :id, :city, :geo_country_id, :geo_state_id, :postal_code]
  
  def self.included(base)
    base.has_many :user_organizations
    base.has_many :users, :through => :user_organizations, :conditions => {:users => {:deleted_at => nil}}
    base.belongs_to :parent_org, :class_name => 'Organization', :foreign_key => :parent_org_id
    base.has_many :satellite_orgs, :class_name => 'Organization',  :foreign_key => :parent_org_id, :conditions => {:deleted_at => nil}
    base.belongs_to :geo_country
    base.belongs_to :geo_state
    base.has_many :model_documents, :as => :documentable
    base.has_many :notes, :as => :notable, :conditions => {:deleted_at => nil}
    base.has_many :group_members, :as => :groupable
    base.has_many :groups, :through => :group_members
    base.has_many :bank_accounts, :foreign_key => :owner_organization_id
    base.after_save :rename_satellites

    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.scope :hq, :conditions => 'organizations.parent_org_id IS NULL'
    base.send :attr_accessor, :force_headquarters
    base.after_save :update_satellite_preference
    
    base.acts_as_audited({:full_model_enabled => false, :except => [:created_by_id, :updated_by_id, :delta, :updated_by, :created_by, :audits]})

    base.geocoded_by :address_for_geocoding do |obj,results|
      # use geocoded result data, replacing user entered data
      if geo = results.first
        obj.latitude = geo.latitude
        obj.longitude = geo.longitude
        obj.city = geo.city
        obj.state_str = geo.state
        obj.state_code = geo.state_code
        obj.country_str = geo.country
        obj.country_code = geo.country_code
        obj.postal_code = geo.postal_code
      end
    end
    base.after_validation :geocode, :if => lambda{ |obj| obj.geocodable? && obj.address_for_geocoding_changed? }

    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
    end

    base.insta_realtime do |insta|
      insta.delta_attributes = SEARCH_ATTRIBUTES
      insta.updated_by_field = :updated_by_id
    end
    base.insta_json do |insta|
      insta.add_method 'state_name'
      insta.add_method 'country_name'
      insta.add_only 'name'
      insta.add_only 'street_address'
      insta.add_only 'street_address2'
      insta.add_only 'city'
      insta.copy_style :simple, :detailed
      insta.add_method 'related_users', :detailed
    end
    
    base.insta_multi
    base.insta_export
    base.insta_lock

    base.insta_template do |insta|
      insta.entity_name = 'organization'
      insta.add_methods [:created_by, :updated_by, :geo_country, :geo_state, :name_and_location, :name, :display_name, :street_address, :street_address2, :city, :state_name, :state_abbreviation, :postal_code, :country_name, :url, :acronym, :bank_accounts, :tax_id, :tax_class_name]
      insta.remove_methods [:id]
    end

    base.validates_presence_of     :name
    base.validates_length_of       :name,    :within => 3..255
    base.insta_favorite
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end
  

  module ModelClassMethods
    def document_title_name
      I18n.t(:Organization)
    end

    # ESH: hack to handle case of Organisation / Organization
    def model_name
      u = ActiveModel::Name.new Organization
      u.instance_variable_set '@human', I18n.t(:Organization)
      u
    end

    def current_grantor
      where(:is_grantor => true).first
    end
    
    # geocode all orgs that havent already been geocoded.  called via rake tasks
    def geocode_all
      Organization.not_geocoded.each do |org|
        unless org.geocodable?
          puts "skipping:  #{org.name} | #{org.address_for_geocoding}"
          next
        end
        puts "geocoding:  #{org.name} | #{org.address_for_geocoding}"
        org.geocode; org.save
      end
    end
  end
  
  module ModelInstanceMethods
    def before_create
      self.url      = clean_url(self.url)
      self.blog_url = clean_url(self.blog_url)
    end
    def before_update
      self.url = clean_url(self.url)
      self.blog_url = clean_url(self.blog_url)
    end
  
    def geo_country= val
      if val.is_a? GeoCountry
        write_attribute(:geo_country, val) 
      elsif
        write_attribute(:geo_country, GeoCountry.find_by_name(val))
      end
    end
    
    # Go up the chain of parents until finding the root parent org without getting into an infinite loop
    def find_parent_or_self
      current_org = self
      counter = 0
      while counter < 500 && current_org.parent_org_id
        current_org = current_org.parent_org
        counter += 1 
      end
      current_org
    end
    

    def geo_state= val
      if val.is_a? GeoState
        write_attribute(:geo_state, val) 
      elsif
        write_attribute(:geo_state, GeoState.find_by_name(val))
      end
    end

    def name_and_location
      autocomplete_to_s
    end
    
    def autocomplete_to_s
      if is_headquarters?
        "#{name} - headquarters"
      else
        "#{name} - #{[street_address, city].compact.join ', '}"
      end
    end
  
    def is_headquarters?
      parent_org_id == nil
    end
    
    def display_name
      name
    end
    
    def satellites
      Organization.where(:id => related_ids).all
    end
  
    def satellite_ids
      Organization.find(:all, :select => :id, :conditions => {:parent_org_id => self.id}).map(&:id)
    end
  
    def related_ids
      [self.id] + satellite_ids
    end
    
    def related_users limit_amount=50
      users.where(:deleted_at => nil).order('last_name asc, first_name asc').limit(limit_amount)
      User.find_by_sql ["SELECT users.* FROM users, user_organizations 
                             WHERE user_organizations.organization_id IN 
                             (select distinct(id) from (select id from organizations where id = ? and deleted_at is null
                              union select id from organizations where parent_org_id = ? and deleted_at is null 
                              union select id from organizations where parent_org_id = (select parent_org_id from organizations where id = ?) and parent_org_id is not null
                              union select parent_org_id from organizations where id = ?) all_orgs where id is not null and deleted_at is null) 
                             AND user_organizations.user_id = users.id and users.deleted_at is null group by users.id
                             order by last_name asc, first_name asc #{limit_amount ? " limit #{limit_amount} " : ''}", self.id, self.id, self.id, self.id]
    end
    
    def has_satellites?
      is_headquarters? && Organization.find(id, :select => "(select count(*) from organizations sat where sat.parent_org_id = organizations.id) satellite_count").satellite_count.to_i
    end
  
    def is_satellite?
      parent_org_id != nil
    end
  
    def state_name
      state_str || (geo_state.name if geo_state)
    end
    
    def state_abbreviation
      state_code || (geo_state.abbreviation if geo_state)
    end
  
    def country_name
      country_str || (geo_country.name if geo_country)
    end

    def tax_class_name
      tax_class.name if tax_class
    end

  
    def to_s
      name.blank? ? nil : name
    end
  
    def merge dup
      unless dup.nil? || self == dup
        Organization.transaction do
          merge_associations dup
    
          # finally remove duplicate
          dup.destroy
        end
      end
    end
  
    # In the implementation, you can override this method or alias_method_chain to put it aside and call it as well 
    def merge_associations dup
      User.connection.execute 'DROP TEMPORARY TABLE IF EXISTS dupe_user_orgs'
      User.connection.execute User.send(:sanitize_sql, ['CREATE TEMPORARY TABLE dupe_user_orgs AS SELECT organization_id, COUNT(*) tot 
          FROM user_organizations WHERE organization_id IN (?) GROUP BY user_id', [self.id]])
      User.connection.execute User.send(:sanitize_sql, ['DELETE FROM user_organizations 
          WHERE organization_id = ? AND user_organizations.organization_id IN (select organization_id from dupe_user_orgs)', dup.id])
      UserOrganization.update_all ['organization_id = ?', self.id], ['organization_id = ?', dup.id] # Now take care of the rest of the user orgs

      # SELECT table_name, column_name FROM information_schema.KEY_COLUMN_USAGE where TABLE_SCHEMA='ef_development' AND REFERENCED_TABLE_NAME='organizations';
      Organization.update_all ['parent_org_id = ?', id], ['parent_org_id = ?', dup.id]
      
      ActiveRecord::Base.connection.execute("SELECT table_name, column_name FROM information_schema.KEY_COLUMN_USAGE where TABLE_SCHEMA='#{ActiveRecord::Base.connection.current_database}' AND REFERENCED_TABLE_NAME='#{self.class.rationalized_table_name}' and REFERENCED_COLUMN_NAME = 'id'").each(:cache_rows => false, :symbolize_keys => true, :as => :hash) do |row|
        klass = self.class.rationalize_klass_from_name row[:table_name]
        if klass
          klass.update_all ["#{row[:column_name]} = ?", id], ["#{row[:column_name]} = ?", dup.id]
        end
      end
    
      # Need to be sure for our polymorphic relations that we're covered
      Note.update_all ['notable_id = ?', self.id], ['notable_type = ? AND notable_id = ?', 'Organization', dup.id]
      ModelDocument.update_all ['documentable_id = ?', self.id], ['documentable_type = ? AND documentable_id = ?', 'Organization', dup.id]
      Favorite.update_all ['favorable_id = ?', self.id], ['favorable_type = ? AND favorable_id = ?', 'Organization', dup.id]
    end
  end
  
  def rename_satellites
    # If this org has been updated and has satellites, need to synchronize the name
    satellites.each do |sat|
      sat.update_attributes :name => self.name unless sat.name == self.name
    end
  end
  
  def realtime_update_id
    parent_org_id ? parent_org_id : id
  end
  
  def update_satellite_preference
    if self.force_headquarters == '1'
      self.force_headquarters = nil # Very important to nil this out, or we could have ourselves an infinite loop on our hands
      if parent_org
        parent_satellites = parent_org.satellites
        parent_satellites.each {|sat_org| sat_org.update_attributes :parent_org_id => self.id}
        parent_org.update_attributes :parent_org_id => self.id
        self.update_attributes :parent_org_id => nil
      end
    end
  end
  
  # dont include street_address2 when geocoding - could introduce bad data if street_address1 is PO Boxes, and 
  def address_for_geocoding
    [street_address, city, state_name, postal_code, country_name].delete_if{|x| x.blank?}.compact.join(', ')
  end

  def address_for_geocoding_changed?
    street_address_changed? || city_changed? || state_str_changed? || country_str_changed? || geo_state_id_changed? || postal_code_changed? || geo_country_id_changed?
  end

  # geocodable if we have either a postal_code, or city and state.
  # This avoids a bunch of records geocoded to same spot if it just has country - i.e. US (which wouldn't add much value)
  def geocodable?
    postal_code.present? || (city.present? && state_name.present?)
  end
  
end
