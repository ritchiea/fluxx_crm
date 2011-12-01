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
      insta.template_map = {:alerts => "alerts", :model_document_templates => "model_document_templates", :additional_settings => "additional_settings", :dynamic_cards => "dynamic_cards"}
      insta.icon_style = ICON_STYLE
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
  end
end