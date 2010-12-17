module FluxxModelDocumentsController
  ICON_STYLE = 'style-wiki'
  def self.included(base)
    base.insta_index ModelDocument do |insta|
      insta.suppress_model_iteration = true
      insta.template = 'model_document_list'
      insta.icon_style = ICON_STYLE
    end
    # The view page will want to pass in the documentable ID and Class
    base.insta_post ModelDocument do |insta|
      insta.pre do |conf|
        if params[:name]
          # Need to grab the file and add it to the model document
          self.pre_model = ModelDocument.new params[:model_document]
          pre_model.model_document_actual_filename = params[:name]
          f = Tempfile.new params[:name]
          f.write request.body.read
          pre_model.document = f
          f.close
        end
      end
      
      insta.format do |format|
        format.html do |triple|
          controller_dsl, outcome, default_block = triple
          render :text => outcome
        end
      end
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit ModelDocument do |insta|
      insta.template = 'model_document_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_put ModelDocument do |insta|
      insta.template = 'model_document_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_delete ModelDocument do |insta|
      insta.format do |format|
        format.html do |triple|
          controller_dsl, outcome, default_block = triple
          render :text => outcome
        end
      end
      insta.icon_style = ICON_STYLE
    end
    base.insta_show ModelDocument do |insta|
      insta.template = 'model_document_show'
      insta.icon_style = ICON_STYLE
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