module FluxxFavoritesController
  def self.included(base)
    base.insta_show Favorite do |insta|
      insta.template = 'favorite_show'
    end
    base.insta_post Favorite do |insta|
      insta.template = 'favorite_form'
    end
    base.insta_delete Favorite do |insta|
      insta.template = 'favorite_form'
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