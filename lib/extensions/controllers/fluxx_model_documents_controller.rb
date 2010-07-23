module FLuxxModelDocumentsController
  def self.included(base)
    # The view page will want to pass in the documentable ID and Class
    base.insta_post ModelDocument do |insta|
      insta.pre do |conf, controller|
        if controller.params[:name]
          # Need to grab the file and add it to the model document
          controller.pre_model = ModelDocument.new controller.params[:model_document]
          f = Tempfile.new controller.params[:name]
          f.write controller.request.body.read
          controller.pre_model.document = f
          f.close
          controller.pre_model.document_file_name = controller.params[:name]
        end
      end
      
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