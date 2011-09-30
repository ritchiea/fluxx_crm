class FluxxCrmCorrectProjectTableToLeaveProjectIdToModelAttrChoices < ActiveRecord::Migration
  def self.up
    execute "insert into model_attribute_choices (client_id, created_at, updated_at, model_attribute_id, model_id, model_attribute_value_id)
    select client_id, now(), now(), (select id from model_attributes
    WHERE  model_attributes.name = 'project_type' and (`model_attributes`.`deleted_at` IS NULL) AND (`model_attributes`.`model_type` IN ('Project'))),
    projects.id, project_type_id
    from projects"
    
    remove_column :projects, :project_type_id
    
  end

  def self.down
    
  end
end