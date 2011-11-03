module FluxxModelDocumentTypesController
  def self.included(base)
    base.insta_index ModelDocumentType do |insta|
      insta.template = 'model_document_type_list'
      insta.results_per_page = 5000
      insta.order_clause = 'name asc'
      insta.suppress_model_iteration = true
    end
    base.insta_show ModelDocumentType do |insta|
      insta.template = 'model_document_type_show'
    end
    base.insta_new ModelDocumentType do |insta|
      insta.template = 'model_document_type_form'
    end
    base.insta_edit ModelDocumentType do |insta|
      insta.template = 'model_document_type_form'
    end
    base.insta_post ModelDocumentType do |insta|
      insta.template = 'model_document_type_form'
    end
    base.insta_put ModelDocumentType do |insta|
      insta.template = 'model_document_type_form'
    end
    base.insta_delete ModelDocumentType do |insta|
      insta.template = 'model_document_type_form'
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