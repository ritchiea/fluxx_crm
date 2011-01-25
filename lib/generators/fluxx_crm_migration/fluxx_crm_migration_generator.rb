require 'rails/generators'
require 'rails/generators/migration'

class FluxxCrmMigrationGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  def self.source_root
    File.join(File.dirname(__FILE__), 'templates')
  end

  # Implement the required interface for Rails::Generators::Migration.
  # taken from http://github.com/rails/rails/blob/master/activerecord/lib/generators/active_record.rb
  def self.next_migration_number(dirname) #:nodoc:
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end
  
  def create_crm_tables
    handle_migration 'create_geo_countries.rb', 'db/migrate/fluxx_crm_create_geo_countries.rb'
    handle_migration 'create_geo_states.rb', 'db/migrate/fluxx_crm_create_geo_states.rb'
    handle_migration 'create_geo_cities.rb', 'db/migrate/fluxx_crm_create_geo_cities.rb'
    handle_migration 'create_geo_regions.rb', 'db/migrate/fluxx_crm_create_geo_regions.rb'
    handle_migration 'create_documents.rb', 'db/migrate/fluxx_crm_create_documents.rb'
    handle_migration 'create_model_documents.rb', 'db/migrate/fluxx_crm_create_model_documents.rb'
    handle_migration 'create_organizations.rb', 'db/migrate/fluxx_crm_create_organizations.rb'
    handle_migration 'create_user_organizations.rb', 'db/migrate/fluxx_crm_create_user_organizations.rb'
    handle_migration 'create_users.rb', 'db/migrate/fluxx_crm_create_users.rb'
    handle_migration 'create_notes.rb', 'db/migrate/fluxx_crm_create_notes.rb'
    handle_migration 'create_favorites.rb', 'db/migrate/fluxx_crm_create_favorites.rb'
    handle_migration 'create_groups.rb', 'db/migrate/fluxx_crm_create_groups.rb'
    handle_migration 'create_group_members.rb', 'db/migrate/fluxx_crm_create_group_members.rb'
    handle_migration 'create_workflow_events.rb', 'db/migrate/fluxx_crm_create_workflow_events.rb'
    handle_migration 'create_role_users.rb', 'db/migrate/fluxx_crm_create_role_users.rb'
    handle_migration 'create_user_profiles.rb', 'db/migrate/fluxx_crm_create_user_profiles.rb'
    handle_migration 'create_user_profile_rules.rb', 'db/migrate/fluxx_crm_create_user_profile_rules.rb'
    handle_migration 'add_allowed_field_to_profile_rules.rb', 'db/migrate/fluxx_crm_add_allowed_field_to_profile_rules.rb'
    handle_migration 'create_model_document_type.rb', 'db/migrate/fluxx_crm_create_model_document_type.rb'
    handle_migration 'create_projects.rb', 'db/migrate/fluxx_crm_create_projects.rb'
    handle_migration 'create_project_lists.rb', 'db/migrate/fluxx_crm_create_project_lists.rb'
    handle_migration 'create_project_list_items.rb', 'db/migrate/fluxx_crm_create_project_list_items.rb'
    handle_migration 'create_project_organizations.rb', 'db/migrate/fluxx_crm_create_project_organizations.rb'
    handle_migration 'create_project_users.rb', 'db/migrate/fluxx_crm_create_project_users.rb'
    handle_migration 'create_wiki_documents.rb', 'db/migrate/fluxx_crm_create_wiki_documents.rb'
    handle_migration 'create_wiki_document_templates.rb', 'db/migrate/fluxx_crm_create_wiki_document_templates.rb'
    handle_migration 'add_description_to_project_relationships.rb', 'db/migrate/fluxx_crm_add_description_to_project_relationships.rb'
    handle_migration 'create_model_document_templates.rb', 'db/migrate/fluxx_crm_create_model_document_templates.rb'
    handle_migration 'remove_deleted_at_from_user_organizations.rb', 'db/migrate/fluxx_crm_remove_deleted_at_from_user_organizations.rb'
    handle_migration 'user_add_column_for_test_user_flag.rb', 'db/migrate/fluxx_crm_user_add_column_for_test_user_flag.rb'
    handle_migration 'add_fields_to_organization.rb', 'db/migrate/fluxx_crm_add_fields_to_organization.rb'
    handle_migration 'create_bank_account.rb', 'db/migrate/fluxx_crm_create_bank_account.rb'
  end
  
  private
  def handle_migration name, filename
    begin
      migration_template name, filename
      sleep 1
    rescue Exception => e
      p e.to_s
    end
  end
end
