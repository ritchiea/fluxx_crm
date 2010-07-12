module FLuxxOrganization
  include ::URLCleaner
  SEARCH_ATTRIBUTES = [:state, :updated_at]
  
  def self.included(base)
    base.has_many :user_organizations
    base.has_many :users, :through => :user_organizations
    base.belongs_to :parent_org, :class_name => 'Organization', :foreign_key => :parent_org_id
    base.has_many :satellite_orgs, :class_name => 'Organization',  :foreign_key => :parent_org_id, :conditions => {:deleted_at => nil}
    base.belongs_to :geo_country
    base.belongs_to :geo_state

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
          merge_associations
        
          # finally remove duplicate
          dup.destroy
        end
      end
    end
  
    # In the implementation, you can override this method or alias_method_chain to put it aside and call it as well 
    def merge_associations
      # move org documents to representant
      dup.documents.update_all ['organization_id = ?', id]
      # move users to corresponendt org
      dup.user_organizations.each do |user_org_assoc|
        user_of_dup = user_org_assoc.user
        if users.include?(user_of_dup)
          # this user already relates to this org.  If the user uses this as their primary org, need to point to the new user org
          if user_org_assoc == user_of_dup.primary_user_organization && user_of_dup.primary_user_organization.organization.id == dup.id
            related_user_org = user_of_dup.user_organizations.find :first, :conditions => {:organization_id => id}
            user_of_dup.update_attribute(:primary_user_organization_id, related_user_org.id) 
          end
          user_org_assoc.destroy
        else
          user_org_assoc.update_attribute(:organization_id, id) 
        end
      end
      Organization.update_all ['parent_org_id = ?', id], ['parent_org_id = ?', dup.id]
    
      # Need to be sure for our polymorphic relations that we're covered
      Note.update_all ['notable_id = ?', self.id], ['notable_type = ? AND notable_id = ?', 'Organization', dup.id]
      Favorite.update_all ['favorable_id = ?', self.id], ['favorable_type = ? AND favorable_id = ?', 'Organization', dup.id]
    end
  end
end