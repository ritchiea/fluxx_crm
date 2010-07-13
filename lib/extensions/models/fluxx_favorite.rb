module FLuxxFavorite
  def self.included(base)
    base.belongs_to :favorable, :polymorphic => true
    base.belongs_to :user

    base.after_commit :update_related_data
    base.insta_search
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def update_related_data
      favorable.update_attribute :delta, 1 if favorable
    end
  end
end