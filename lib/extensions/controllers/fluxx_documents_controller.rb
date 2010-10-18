module FluxxDocumentsController
  def self.included(base)
    base.insta_index Document do |insta|
      insta.suppress_model_iteration = true
      insta.template = 'document_list'
    end

    base.insta_post Document do |insta|
      insta.pre do |conf, controller|
        if controller.params[:name]
          # Need to grab the file and add it to the document
          controller.pre_model = Document.new controller.params[:document]
          f = Tempfile.new controller.params[:name]
          f.write controller.request.body.read
          controller.pre_model.document = f
          f.close
          controller.pre_model.document_file_name = controller.params[:name]
        end
      end
      
      insta.format do |format|
        format.html do |controller_dsl, controller, outcome, default_block|
          controller.render :text => outcome
        end
      end
    end
    base.insta_delete Document do |insta|
      insta.format do |format|
        format.html do |controller_dsl, controller, outcome, default_block|
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