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
  
  def create_geo_tables
    handle_migration 'create_geo_countries.rb', 'db/migrate/fluxx_crm_create_geo_countries.rb'
    sleep 1
    handle_migration 'create_geo_states.rb', 'db/migrate/fluxx_crm_create_geo_states.rb'
    sleep 1
    handle_migration 'create_geo_cities.rb', 'db/migrate/fluxx_crm_create_geo_cities.rb'
    sleep 1
    handle_migration 'create_documents.rb', 'db/migrate/fluxx_crm_create_model_documents.rb'
    sleep 1
    handle_migration 'create_organizations.rb', 'db/migrate/fluxx_crm_create_organizations.rb'
    sleep 1
    handle_migration 'create_user_organizations.rb', 'db/migrate/fluxx_crm_create_user_organizations.rb'
    sleep 1
    handle_migration 'create_users.rb', 'db/migrate/fluxx_crm_create_users.rb'
    sleep 1
    handle_migration 'create_notes.rb', 'db/migrate/fluxx_crm_create_notes.rb'
    sleep 1
    handle_migration 'create_favorites.rb', 'db/migrate/fluxx_crm_create_favorites.rb'
    sleep 1
    handle_migration 'create_groups.rb', 'db/migrate/fluxx_crm_create_groups.rb'
    sleep 1
    handle_migration 'create_group_members.rb', 'db/migrate/fluxx_crm_create_group_members.rb'
    sleep 1
  end
  
  private
  def handle_migration name, filename
    begin
      migration_template name, filename
    rescue Exception => e
      p e.to_s
    end
  end
end