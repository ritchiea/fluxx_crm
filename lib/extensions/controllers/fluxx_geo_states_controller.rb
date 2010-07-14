module FLuxxGeoStatesController
  def self.included(base)
    base.insta_index GeoState do |insta|
      insta.template = 'geo_state_list'
    end
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