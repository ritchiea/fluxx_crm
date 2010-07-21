module FLuxxOrganization
  include ::URLCleaner
  SEARCH_ATTRIBUTES = [:state, :updated_at, :name, :id]
  
  def self.included(base)
    base.has_many :user_organizations
    base.has_many :users, :through => :user_organizations
    base.belongs_to :parent_org, :class_name => 'Organization', :foreign_key => :parent_org_id
    base.has_many :satellite_orgs, :class_name => 'Organization',  :foreign_key => :parent_org_id, :conditions => {:deleted_at => nil}
    base.belongs_to :geo_country
    base.belongs_to :geo_state
    base.has_many :favorites, :as => :favorable
    base.has_many :model_documents, :as => :documentable
    base.has_many :notes, :as => :notable
    base.has_many :group_members, :as => :groupable

    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :modified_by, :class_name => 'User', :foreign_key => 'modified_by_id'
    base.scope :hq, :conditions => 'organizations.parent_org_id IS NULL'
    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta]})

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

    base.validates_presence_of     :name
    base.validates_length_of       :name,    :within => 3..100
    
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end
  

  module ModelClassMethods
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
  
    def country= val
      if val.is_a? Country
        write_attribute(:country, val) 
      elsif
        write_attribute(:country, Country.find_by_name(val))
      end
    end

    def country_state= val
      if val.is_a? CountryState
        write_attribute(:country_state, val) 
      elsif
        write_attribute(:country_state, CountryState.find_by_name(val))
      end
    end
  
    def auto_complete_name
      if is_headquarters?
        "#{name} - headquarters"
      else
        "#{name} - #{[street_address, city].compact.join ', '}"
      end
    end
  
    def is_headquarters?
      parent_org_id == nil
    end
  
    def satellite_ids
      Organization.find(:all, :select => :id, :conditions => {:parent_org_id => self.id}).map(&:id)
    end
  
    def related_ids
      [self.id] + satellite_ids
    end

    def has_satellites?
      is_headquarters? && Organization.find(id, :select => "(select count(*) from organizations sat where sat.parent_org_id = organizations.id) satellite_count").satellite_count.to_i
    end
  
    def is_satellite?
      parent_org_id != nil
    end
  
    def state_name
      country_state.name if country_state
    end
    
    def state_abbreviation
      country_state.abbreviation if country_state
    end
  
    def country_name
      country.name if country
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
      User.connection.execute 'DROP TABLE IF EXISTS dupe_user_orgs'
      User.connection.execute User.send(:sanitize_sql, ['CREATE TEMPORARY TABLE dupe_user_orgs AS SELECT organization_id, COUNT(*) tot 
          FROM user_organizations WHERE organization_id IN (?) GROUP BY user_id', [self.id]])
      User.connection.execute User.send(:sanitize_sql, ['DELETE FROM user_organizations 
          WHERE organization_id = ? AND user_organizations.organization_id IN (select organization_id from dupe_user_orgs)', dup.id])
      UserOrganization.update_all ['organization_id = ?', self.id], ['organization_id = ?', dup.id] # Now take care of the rest of the user orgs
      
      Organization.update_all ['parent_org_id = ?', id], ['parent_org_id = ?', dup.id]
    
      # Need to be sure for our polymorphic relations that we're covered
      Note.update_all ['notable_id = ?', self.id], ['notable_type = ? AND notable_id = ?', 'Organization', dup.id]
      Favorite.update_all ['favorable_id = ?', self.id], ['favorable_type = ? AND favorable_id = ?', 'Organization', dup.id]
    end
  end
end