class ActiveRecord::ModelDslFormBuilder < ActiveRecord::ModelDsl
  attr_accessor :form_templates
  
  def add_form_template form_type, form_path, description
    form_templates << {:form_type => form_type, :form_path => form_path, :description => description}
  end

  def initialize model_class
    super model_class
    self.form_templates = []
  end

end