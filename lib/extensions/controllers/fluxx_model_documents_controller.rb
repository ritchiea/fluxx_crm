module FLuxxModelDocumentsController
  def self.included(base)
    # The view page will want to pass in the documentable ID and Class
    base.insta_post ModelDocument do |insta|
      insta.template = 'model_document_form'
    end
    base.insta_delete ModelDocument do |insta|
      insta.template = 'model_document_form'
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