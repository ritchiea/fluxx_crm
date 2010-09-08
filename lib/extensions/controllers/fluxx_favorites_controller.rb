module FluxxFavoritesController
  def self.included(base)
    base.insta_show Favorite do |insta|
      insta.template = 'favorite_show'
    end
    base.insta_post Favorite do |insta|
      insta.pre do |controller_dsl, controller|
        if controller.params[:favorite] && controller.params[:favorite][:favorable_id] && controller.params[:favorite][:favorable_type] && controller.params[:favorite][:user_id]
          controller.pre_model = Favorite.where(:favorable_id => controller.params[:favorite][:favorable_id], :favorable_type => controller.params[:favorite][:favorable_type], :user_id => controller.params[:favorite][:user_id]).first
        end
      end
      
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