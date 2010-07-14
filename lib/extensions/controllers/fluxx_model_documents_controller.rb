module FLuxxModelDocumentsController
  def self.included(base)
    # The view page will want to pass in the documentable ID and Class
    base.insta_post ModelDocument do |insta|
      insta.format do |format|
        format.html do |controller_dsl, controller, outcome|
          controller.render :text => outcome
        end
      end
    end
    base.insta_delete ModelDocument do |insta|
      insta.format do |format|
        format.html do |controller_dsl, controller, outcome|
          controller.render :text => outcome
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