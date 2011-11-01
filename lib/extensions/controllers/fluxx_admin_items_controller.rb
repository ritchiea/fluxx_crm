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
      insta.template_map = {:alerts => "alerts", :model_document_templates => "model_document_templates"}
      allowed_models = ["Deal", "Request", "RequestReport", "User", "Organization", "ProjectList", "Project", "Program", "Loi", "FundingSourceAllocationAuthority"]
      insta.icon_style = ICON_STYLE
      all_model_types = Module.constants.select do |constant_name|
        constant = eval constant_name
        constant if not constant.nil? and constant.is_a? Class and constant.superclass == ActiveRecord::Base and allowed_models.include? constant_name
      end.sort
      insta.pre do |conf|
        @all_model_types = all_model_types
      end
    end
  end



    #base.extend(ModelClassMethods)
    #base.class_eval do
    #  include ModelInstanceMethods
    #end

  module ModelClassMethods
  end

  module ModelInstanceMethods
  end
end