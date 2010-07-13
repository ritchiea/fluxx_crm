module FLuxxGeoCountriesController
  def self.included(base)
    base.insta_index GeoCountry do |insta|
      insta.format do |format|
        format.json do |controller_dsl, controller, outcome|
          controller.render :inline => @models.to_json
        end
      end
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