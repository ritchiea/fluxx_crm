module FluxxAdminItemsController
  ICON_STYLE = 'style-admins'
  def self.included(base)
    base.insta_index do |insta|
      insta.template = 'model_attribute_list'
      insta.suppress_model_iteration
      insta.format do |format|
        format.html do |triple|
          controller_dsl, outcome, default_block = triple
          render :layout => false
        end
      end
    end

    base.insta_edit do |insta|
      insta.template = "model_types"
      insta.template_map = {:alerts => "alerts", :model_document_templates => "model_document_templates", :additional_settings => "additional_settings", :dynamic_cards => "dynamic_cards", :roles_and_profiles => "roles_and_profiles"}
      insta.icon_style = ICON_STYLE
      insta.post do |triple|
        controller_dsl, model, outcome = triple
        @model_types = ActiveRecord::Base.all_formbuilder_model_types_collection
      end
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
  end
end