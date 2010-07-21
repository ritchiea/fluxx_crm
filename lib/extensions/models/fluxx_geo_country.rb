module FLuxxGeoCountry
  SEARCH_ATTRIBUTES = [:created_at, :updated_at, :name]

  def self.included(base)
    base.has_many :geo_states
    base.acts_as_audited
    
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
    end
    base.insta_export
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def find_related_geo_states
      GeoState.where(:geo_country_id => self.id).all
    end
    
    def to_s
      name.blank? ? nil : name
    end
    
    def abbreviation
      fips104
    end
  end
end