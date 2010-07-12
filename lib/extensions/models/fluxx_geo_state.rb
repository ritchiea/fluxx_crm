module FLuxxGeoState
  def self.included(base)
    base.belongs_to :geo_country
    base.has_many :geo_cities
    base.acts_as_audited

    base.validates_presence_of :geo_country

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def to_s
      name
    end
  end
end