module FluxxBankAccount
  SEARCH_ATTRIBUTES = [:created_at, :updated_at, :id, :name, :owner_organization_id, :owner_user_id]
  LIQUID_METHODS = [:name, :account_name, :account_number]  
  
  def self.included(base)
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.belongs_to :geo_country, :class_name => 'GeoCountry', :foreign_key => :geo_country_id
    base.belongs_to :geo_state, :class_name => 'GeoState', :foreign_key => :geo_state_id
    base.belongs_to :owner_user, :class_name => 'User', :foreign_key => 'owner_user_id'
    base.belongs_to :owner_organization, :class_name => 'Organization', :foreign_key => 'owner_organization_id'
    base.send :attr_accessor, :organization_lookup

    base.acts_as_audited({:full_model_enabled => false, :except => [:created_by_id, :updated_by_id, :delta, :updated_by, :created_by, :audits]})

    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
      insta.derived_filters = {}
    end

    base.insta_multi
    base.insta_lock

    base.insta_template do |insta|
      insta.entity_name = 'bank_account'
      insta.add_methods []
      insta.remove_methods [:id]
    end
    base.liquid_methods *( LIQUID_METHODS )    

    base.insta_utc do |insta|
      insta.time_attributes = [] 
    end
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
    
  end
  

  module ModelClassMethods
  end
  
  module ModelInstanceMethods
    def autocomplete_to_s
      "#{bank_name} #{account_number ? " - #{account_number}" : ''}"
    end
    
    def to_s
      autocomplete_to_s
    end
  end
end