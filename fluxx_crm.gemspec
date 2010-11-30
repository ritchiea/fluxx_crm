# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{fluxx_crm}
  s.version = "0.0.14"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Eric Hansen"]
  s.date = %q{2010-11-30}
  s.email = %q{fluxx@acesfconsulting.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.textile"
  ]
  s.files = [
    "app/controllers/application_controller.rb",
     "app/controllers/documents_controller.rb",
     "app/controllers/favorites_controller.rb",
     "app/controllers/geo_cities_controller.rb",
     "app/controllers/geo_countries_controller.rb",
     "app/controllers/geo_states_controller.rb",
     "app/controllers/group_members_controller.rb",
     "app/controllers/groups_controller.rb",
     "app/controllers/model_document_templates_controller.rb",
     "app/controllers/model_document_types_controller.rb",
     "app/controllers/model_documents_controller.rb",
     "app/controllers/notes_controller.rb",
     "app/controllers/organizations_controller.rb",
     "app/controllers/project_list_items_controller.rb",
     "app/controllers/project_lists_controller.rb",
     "app/controllers/project_organizations_controller.rb",
     "app/controllers/project_users_controller.rb",
     "app/controllers/projects_controller.rb",
     "app/controllers/role_users_controller.rb",
     "app/controllers/user_organizations_controller.rb",
     "app/controllers/users_controller.rb",
     "app/controllers/wiki_document_templates_controller.rb",
     "app/controllers/wiki_documents_controller.rb",
     "app/helpers/application_helper.rb",
     "app/models/document.rb",
     "app/models/favorite.rb",
     "app/models/geo_city.rb",
     "app/models/geo_country.rb",
     "app/models/geo_region.rb",
     "app/models/geo_state.rb",
     "app/models/group.rb",
     "app/models/group_member.rb",
     "app/models/model_document.rb",
     "app/models/model_document_template.rb",
     "app/models/model_document_type.rb",
     "app/models/note.rb",
     "app/models/organization.rb",
     "app/models/project.rb",
     "app/models/project_list.rb",
     "app/models/project_list_item.rb",
     "app/models/project_organization.rb",
     "app/models/project_user.rb",
     "app/models/role_user.rb",
     "app/models/user.rb",
     "app/models/user_organization.rb",
     "app/models/user_profile.rb",
     "app/models/user_profile_rule.rb",
     "app/models/wiki_document.rb",
     "app/models/wiki_document_template.rb",
     "app/models/workflow_event.rb",
     "app/stylesheets/theme/default/style.sass",
     "app/views/audits/_list_audits.html.haml",
     "app/views/favorites/_favorite_form.html.haml",
     "app/views/favorites/_favorite_list.html.haml",
     "app/views/favorites/_favorite_show.html.haml",
     "app/views/geo_cities/_geo_city_form.html.haml",
     "app/views/geo_cities/_geo_city_list.html.haml",
     "app/views/geo_cities/_geo_city_show.html.haml",
     "app/views/geo_countries/_geo_country_form.html.haml",
     "app/views/geo_countries/_geo_country_list.html.haml",
     "app/views/geo_countries/_geo_country_show.html.haml",
     "app/views/geo_states/_geo_state_form.html.haml",
     "app/views/geo_states/_geo_state_list.html.haml",
     "app/views/geo_states/_geo_state_show.html.haml",
     "app/views/group_members/_group_member_form.html.haml",
     "app/views/group_members/_group_member_list.html.haml",
     "app/views/group_members/_group_member_show.html.haml",
     "app/views/group_members/_list_group_members.html.haml",
     "app/views/insta/_show_action_buttons.html.haml",
     "app/views/insta/_show_buttons.html.haml",
     "app/views/layouts/printable_show.html.haml",
     "app/views/model_document_templates/_model_document_template_form.html.haml",
     "app/views/model_document_templates/_model_document_template_list.html.haml",
     "app/views/model_document_templates/_model_document_template_show.html.haml",
     "app/views/model_document_types/_model_document_list.html.haml",
     "app/views/model_documents/_list_model_documents.html.haml",
     "app/views/model_documents/_model_document_form.html.haml",
     "app/views/model_documents/_model_document_list.html.haml",
     "app/views/model_documents/_model_document_show.html.haml",
     "app/views/notes/_list_notes.html.haml",
     "app/views/notes/_note_form.html.haml",
     "app/views/notes/_note_list.html.haml",
     "app/views/notes/_note_show.html.haml",
     "app/views/organizations/_organization_form.html.haml",
     "app/views/organizations/_organization_list.html.haml",
     "app/views/organizations/_organization_location.html.haml",
     "app/views/organizations/_organization_satellites.html.haml",
     "app/views/organizations/_organization_show.html.haml",
     "app/views/organizations/_single_org_lookup.html.haml",
     "app/views/project_list_items/_list_project_list_items.html.haml",
     "app/views/project_list_items/_project_list_item_form.html.haml",
     "app/views/project_list_items/_project_list_item_list.html.haml",
     "app/views/project_list_items/_project_list_item_show.html.haml",
     "app/views/project_lists/_list_project_lists.html.haml",
     "app/views/project_lists/_project_list_form.html.haml",
     "app/views/project_lists/_project_list_list.html.haml",
     "app/views/project_lists/_project_list_show.html.haml",
     "app/views/project_organizations/_list_project_organizations.html.haml",
     "app/views/project_organizations/_project_organization_add.html.haml",
     "app/views/project_organizations/_project_organization_form.html.haml",
     "app/views/project_organizations/_project_organization_list.html.haml",
     "app/views/project_organizations/_project_organization_show.html.haml",
     "app/views/project_users/_list_project_users.html.haml",
     "app/views/project_users/_project_user_add.html.haml",
     "app/views/project_users/_project_user_form.html.haml",
     "app/views/project_users/_project_user_list.html.haml",
     "app/views/project_users/_project_user_show.html.haml",
     "app/views/projects/_project_form.html.haml",
     "app/views/projects/_project_list.html.haml",
     "app/views/projects/_project_show.html.haml",
     "app/views/role_users/_role_user_form.html.haml",
     "app/views/role_users/_role_user_list.html.haml",
     "app/views/role_users/_role_user_show.html.haml",
     "app/views/user_organizations/_list_user_organizations.html.haml",
     "app/views/user_organizations/_user_organization_form.html.haml",
     "app/views/user_organizations/_user_organization_list.html.haml",
     "app/views/user_organizations/_user_organization_show.html.haml",
     "app/views/users/_admin_user.html.haml",
     "app/views/users/_related_users.html.haml",
     "app/views/users/_user_form.html.haml",
     "app/views/users/_user_form_header.html.haml",
     "app/views/users/_user_list.html.haml",
     "app/views/users/_user_roles.html.haml",
     "app/views/users/_user_show.html.haml",
     "app/views/wiki_document_templates/_wiki_document_template_form.html.haml",
     "app/views/wiki_document_templates/_wiki_document_template_list.html.haml",
     "app/views/wiki_document_templates/_wiki_document_template_show.html.haml",
     "app/views/wiki_documents/_list_wiki_documents.html.haml",
     "app/views/wiki_documents/_wiki_document_form.html.haml",
     "app/views/wiki_documents/_wiki_document_list.html.haml",
     "app/views/wiki_documents/_wiki_document_show.html.haml",
     "config/routes.rb",
     "lib/extensions/action_controller/base.rb",
     "lib/extensions/action_controller/controller_dsl_role.rb",
     "lib/extensions/action_controller/controller_dsl_show.rb",
     "lib/extensions/action_controller/controller_dsl_update.rb",
     "lib/extensions/active_record/base.rb",
     "lib/extensions/active_record/model_dsl_workflow.rb",
     "lib/extensions/controllers/fluxx_documents_controller.rb",
     "lib/extensions/controllers/fluxx_favorites_controller.rb",
     "lib/extensions/controllers/fluxx_geo_cities_controller.rb",
     "lib/extensions/controllers/fluxx_geo_countries_controller.rb",
     "lib/extensions/controllers/fluxx_geo_states_controller.rb",
     "lib/extensions/controllers/fluxx_group_members_controller.rb",
     "lib/extensions/controllers/fluxx_groups_controller.rb",
     "lib/extensions/controllers/fluxx_model_document_templates_controller.rb",
     "lib/extensions/controllers/fluxx_model_document_types_controller.rb",
     "lib/extensions/controllers/fluxx_model_documents_controller.rb",
     "lib/extensions/controllers/fluxx_notes_controller.rb",
     "lib/extensions/controllers/fluxx_organizations_controller.rb",
     "lib/extensions/controllers/fluxx_project_list_items_controller.rb",
     "lib/extensions/controllers/fluxx_project_lists_controller.rb",
     "lib/extensions/controllers/fluxx_project_organizations_controller.rb",
     "lib/extensions/controllers/fluxx_project_users_controller.rb",
     "lib/extensions/controllers/fluxx_projects_controller.rb",
     "lib/extensions/controllers/fluxx_role_users_controller.rb",
     "lib/extensions/controllers/fluxx_user_organizations_controller.rb",
     "lib/extensions/controllers/fluxx_users_controller.rb",
     "lib/extensions/controllers/fluxx_wiki_document_templates_controller.rb",
     "lib/extensions/controllers/fluxx_wiki_documents_controller.rb",
     "lib/extensions/models/fluxx_document.rb",
     "lib/extensions/models/fluxx_favorite.rb",
     "lib/extensions/models/fluxx_geo_city.rb",
     "lib/extensions/models/fluxx_geo_country.rb",
     "lib/extensions/models/fluxx_geo_region.rb",
     "lib/extensions/models/fluxx_geo_state.rb",
     "lib/extensions/models/fluxx_group.rb",
     "lib/extensions/models/fluxx_group_member.rb",
     "lib/extensions/models/fluxx_model_document.rb",
     "lib/extensions/models/fluxx_model_document_template.rb",
     "lib/extensions/models/fluxx_model_document_type.rb",
     "lib/extensions/models/fluxx_note.rb",
     "lib/extensions/models/fluxx_organization.rb",
     "lib/extensions/models/fluxx_project.rb",
     "lib/extensions/models/fluxx_project_list.rb",
     "lib/extensions/models/fluxx_project_list_item.rb",
     "lib/extensions/models/fluxx_project_organization.rb",
     "lib/extensions/models/fluxx_project_user.rb",
     "lib/extensions/models/fluxx_role_user.rb",
     "lib/extensions/models/fluxx_user.rb",
     "lib/extensions/models/fluxx_user_organization.rb",
     "lib/extensions/models/fluxx_user_profile.rb",
     "lib/extensions/models/fluxx_user_profile_rule.rb",
     "lib/extensions/models/fluxx_wiki_document.rb",
     "lib/extensions/models/fluxx_wiki_document_template.rb",
     "lib/extensions/models/fluxx_workflow_event.rb",
     "lib/fluxx_crm.rb",
     "lib/fluxx_crm/engine.rb",
     "lib/generators/fluxx_crm_migration/fluxx_crm_migration_generator.rb",
     "lib/generators/fluxx_crm_migration/templates/add_allowed_field_to_profile_rules.rb",
     "lib/generators/fluxx_crm_migration/templates/add_description_to_project_relationships.rb",
     "lib/generators/fluxx_crm_migration/templates/create_documents.rb",
     "lib/generators/fluxx_crm_migration/templates/create_favorites.rb",
     "lib/generators/fluxx_crm_migration/templates/create_geo_cities.rb",
     "lib/generators/fluxx_crm_migration/templates/create_geo_countries.rb",
     "lib/generators/fluxx_crm_migration/templates/create_geo_regions.rb",
     "lib/generators/fluxx_crm_migration/templates/create_geo_states.rb",
     "lib/generators/fluxx_crm_migration/templates/create_group_members.rb",
     "lib/generators/fluxx_crm_migration/templates/create_groups.rb",
     "lib/generators/fluxx_crm_migration/templates/create_model_document_templates.rb",
     "lib/generators/fluxx_crm_migration/templates/create_model_document_type.rb",
     "lib/generators/fluxx_crm_migration/templates/create_model_documents.rb",
     "lib/generators/fluxx_crm_migration/templates/create_notes.rb",
     "lib/generators/fluxx_crm_migration/templates/create_organizations.rb",
     "lib/generators/fluxx_crm_migration/templates/create_project_list_items.rb",
     "lib/generators/fluxx_crm_migration/templates/create_project_lists.rb",
     "lib/generators/fluxx_crm_migration/templates/create_project_organizations.rb",
     "lib/generators/fluxx_crm_migration/templates/create_project_users.rb",
     "lib/generators/fluxx_crm_migration/templates/create_projects.rb",
     "lib/generators/fluxx_crm_migration/templates/create_role_users.rb",
     "lib/generators/fluxx_crm_migration/templates/create_user_organizations.rb",
     "lib/generators/fluxx_crm_migration/templates/create_user_profile_rules.rb",
     "lib/generators/fluxx_crm_migration/templates/create_user_profiles.rb",
     "lib/generators/fluxx_crm_migration/templates/create_users.rb",
     "lib/generators/fluxx_crm_migration/templates/create_wiki_document_templates.rb",
     "lib/generators/fluxx_crm_migration/templates/create_wiki_documents.rb",
     "lib/generators/fluxx_crm_migration/templates/create_workflow_events.rb",
     "lib/generators/fluxx_crm_public/fluxx_crm_public_generator.rb",
     "lib/tasks.rb",
     "public/images/README.txt",
     "public/javascripts/application_crm.js",
     "public/stylesheets/README.txt"
  ]
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Fluxx CRM Core}
  s.test_files = [
    "test/blueprint.rb",
     "test/dummy/app/controllers/application_controller.rb",
     "test/dummy/app/controllers/races_controller.rb",
     "test/dummy/app/helpers/application_helper.rb",
     "test/dummy/app/helpers/race_helper.rb",
     "test/dummy/app/models/race.rb",
     "test/dummy/app/models/user.rb",
     "test/dummy/config/application.rb",
     "test/dummy/config/boot.rb",
     "test/dummy/config/environment.rb",
     "test/dummy/config/environments/development.rb",
     "test/dummy/config/environments/production.rb",
     "test/dummy/config/environments/test.rb",
     "test/dummy/config/initializers/backtrace_silencers.rb",
     "test/dummy/config/initializers/inflections.rb",
     "test/dummy/config/initializers/mime_types.rb",
     "test/dummy/config/initializers/secret_token.rb",
     "test/dummy/config/initializers/session_store.rb",
     "test/dummy/config/routes.rb",
     "test/dummy/db/migrate/20100708173516_fluxx_crm_create_geo_countries.rb",
     "test/dummy/db/migrate/20100708173517_fluxx_crm_create_geo_states.rb",
     "test/dummy/db/migrate/20100712163807_acts_as_audited_migration.rb",
     "test/dummy/db/migrate/20100712164109_fluxx_engine_create_realtime_updates_table.rb",
     "test/dummy/db/migrate/20100712164110_fluxx_engine_create_multi_element_groups.rb",
     "test/dummy/db/migrate/20100712164111_fluxx_engine_create_multi_element_values.rb",
     "test/dummy/db/migrate/20100712164112_fluxx_engine_create_multi_element_choices.rb",
     "test/dummy/db/migrate/20100712164113_fluxx_engine_create_client_stores.rb",
     "test/dummy/db/migrate/20100712182238_fluxx_crm_create_favorites.rb",
     "test/dummy/db/migrate/20100712182240_fluxx_crm_create_group_members.rb",
     "test/dummy/db/migrate/20100713221659_fluxx_crm_create_organizations.rb",
     "test/dummy/db/migrate/20100713221700_fluxx_crm_create_user_organizations.rb",
     "test/dummy/db/migrate/20100713221701_fluxx_crm_create_users.rb",
     "test/dummy/db/migrate/20100713221702_fluxx_crm_create_notes.rb",
     "test/dummy/db/migrate/20100713221842_fluxx_crm_create_model_documents.rb",
     "test/dummy/db/migrate/20100715163024_fluxx_crm_create_geo_cities.rb",
     "test/dummy/db/migrate/20100720033741_fluxx_crm_create_groups.rb",
     "test/dummy/db/migrate/20100723040020_fluxx_crm_create_workflow_events.rb",
     "test/dummy/db/migrate/20100725015340_create_races.rb",
     "test/dummy/db/migrate/20100804140632_fluxx_crm_create_role_users.rb",
     "test/dummy/db/migrate/20101018230021_fluxx_crm_create_documents.rb",
     "test/dummy/db/migrate/20101018232829_fluxx_crm_create_geo_regions.rb",
     "test/dummy/db/migrate/20101021202843_fluxx_crm_create_user_profiles.rb",
     "test/dummy/db/migrate/20101021202844_fluxx_crm_create_user_profile_rules.rb",
     "test/dummy/db/migrate/20101025182406_fluxx_crm_add_allowed_field_to_profile_rules.rb",
     "test/dummy/db/migrate/20101025182407_fluxx_crm_create_model_document_type.rb",
     "test/dummy/db/migrate/20101101232320_fluxx_crm_create_projects.rb",
     "test/dummy/db/migrate/20101101232321_fluxx_crm_create_project_lists.rb",
     "test/dummy/db/migrate/20101101232322_fluxx_crm_create_project_list_items.rb",
     "test/dummy/db/migrate/20101101232323_fluxx_crm_create_project_organizations.rb",
     "test/dummy/db/migrate/20101101232324_fluxx_crm_create_project_users.rb",
     "test/dummy/db/migrate/20101101232439_fluxx_crm_create_wiki_documents.rb",
     "test/dummy/db/migrate/20101122221510_fluxx_crm_create_wiki_document_templates.rb",
     "test/dummy/db/migrate/20101123020723_fluxx_crm_add_description_to_project_relationships.rb",
     "test/dummy/db/migrate/20101127174035_fluxx_crm_create_model_document_templates.rb",
     "test/dummy/db/schema.rb",
     "test/fluxx_crm_test.rb",
     "test/functional/documents_controller_test.rb",
     "test/functional/favorites_controller_test.rb",
     "test/functional/geo_cities_controller_test.rb",
     "test/functional/geo_countries_controller_test.rb",
     "test/functional/geo_states_controller_test.rb",
     "test/functional/group_members_controller_test.rb",
     "test/functional/groups_controller_test.rb",
     "test/functional/model_document_templates_controller_test.rb",
     "test/functional/model_documents_controller_test.rb",
     "test/functional/notes_controller_test.rb",
     "test/functional/organizations_controller_test.rb",
     "test/functional/project_list_items_controller_test.rb",
     "test/functional/project_lists_controller_test.rb",
     "test/functional/project_organizations_controller_test.rb",
     "test/functional/project_users_controller_test.rb",
     "test/functional/projects_controller_test.rb",
     "test/functional/races_controller_test.rb",
     "test/functional/role_users_controller_test.rb",
     "test/functional/user_organizations_controller_test.rb",
     "test/functional/users_controller_test.rb",
     "test/functional/wiki_document_templates_controller_test.rb",
     "test/functional/wiki_documents_controller_test.rb",
     "test/integration/navigation_test.rb",
     "test/support/integration_case.rb",
     "test/test_helper.rb",
     "test/unit/action_controller/controller_dsl_role_test.rb",
     "test/unit/active_record/model_dsl_workflow_test.rb",
     "test/unit/models/favorite_test.rb",
     "test/unit/models/geo_city_test.rb",
     "test/unit/models/geo_country_test.rb",
     "test/unit/models/geo_state_test.rb",
     "test/unit/models/group_test.rb",
     "test/unit/models/model_document_test.rb",
     "test/unit/models/note_test.rb",
     "test/unit/models/organization_test.rb",
     "test/unit/models/project_list_item_test.rb",
     "test/unit/models/project_list_test.rb",
     "test/unit/models/project_organization_test.rb",
     "test/unit/models/project_test.rb",
     "test/unit/models/project_user_test.rb",
     "test/unit/models/role_user_test.rb",
     "test/unit/models/user_organization_test.rb",
     "test/unit/models/user_test.rb",
     "test/unit/models/wiki_document_test.rb",
     "test/unit/models/workflow_event_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

