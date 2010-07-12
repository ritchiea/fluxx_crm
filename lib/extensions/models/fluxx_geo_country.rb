module FLuxxGeoCountry
  def self.included(base)
    base.has_many :geo_states
    base.acts_as_audited
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
  end
end