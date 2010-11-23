require 'machinist/active_record'
require 'sham'

require 'faker'

ATTRIBUTES = {}

def bp_attrs
  ATTRIBUTES
end

# For faker formats see http://faker.rubyforge.org/rdoc/

Sham.document { Tempfile.new('the attached document') }
Sham.word { Faker::Lorem.words(2).join '' }
Sham.words { Faker::Lorem.words(3).join ' ' }
Sham.sentence { Faker::Lorem.sentence }
Sham.company_name { Faker::Company.name }
Sham.first_name { Faker::Name.first_name }
Sham.last_name { Faker::Name.last_name }
Sham.login { Faker::Internet.user_name }
Sham.email { Faker::Internet.email }
Sham.url { "http://#{Faker::Internet.domain_name}/#{Faker::Lorem.words(1).first}"  }

User.blueprint do
  first_name Sham.first_name
  last_name Sham.last_name
  login(Sham.login + 'abcdef')
  email Sham.email
  created_at 5.days.ago.to_s(:db)
  state 'active'
end


Organization.blueprint do
  name Sham.company_name
  city Sham.words
  street_address Sham.words
  street_address2 Sham.words
  url Sham.url
end

UserOrganization.blueprint do
  title Sham.words
  user_id User.make.id
  organization_id Organization.make.id
end

GeoCountry.blueprint do
  name do
    Sham.word
  end
  iso3 Sham.word
  fips104 Sham.word
end

GeoState.blueprint do
  name Sham.word
  abbreviation Sham.word
  fips_10_4 Sham.word
  geo_country_id GeoCountry.make.id
end

GeoCity.blueprint do
  name Sham.word
  geo_state_id GeoState.make.id
  geo_country_id GeoCountry.make.id
  original_id 1
end

ModelDocument.blueprint do
  documentable do
    User.make
  end
  document Sham.document
end

# this helper class creates classes so your blueprint is happy
class Documentable
  def self.make(attrs = {})
  end
end

Document.blueprint do
  document Sham.document
end

Note.blueprint do
  note Sham.sentence
  notable_type 'User'
  notable_id User.make.id
end

Group.blueprint do
  name Sham.word
end

GroupMember.blueprint do
end

Favorite.blueprint do
  favorable_type 'User'
  favorable_id 1
end

Note.blueprint do
  note Sham.sentence
  notable_type 'User'
  notable_id User.make.id
end

Audit.blueprint do
  action 'create'
end

WorkflowEvent.blueprint do
  ip_address '127.0.0.1'
  old_state 'old_state'
  new_state 'new_state'
  comment 'comment'
end

Race.blueprint do
  name Sham.word
end

RoleUser.blueprint do
  name Sham.word
end

UserProfile.blueprint do
  name 'board'
end

UserProfileRule.blueprint do
end

Project.blueprint do
  title Sham.sentence
  description Sham.sentence
end

ProjectList.blueprint do
  title Sham.sentence
  list_order 1
end

ProjectUser.blueprint do
end

ProjectOrganization.blueprint do
end

ProjectListItem.blueprint do
  name Sham.word
  list_item_text Sham.sentence
  due_at Time.now
  item_order 1
end

WikiDocument.blueprint do
  model_type Organization.name
  wiki_order 1
  title Sham.word
  note Sham.sentence
end

WikiDocumentTemplate.blueprint do
  model_type Organization.name
  document_type Sham.word
  filename Sham.word
  description Sham.word
  category Sham.word
  document Sham.sentence
end



def setup_multi_element_groups
  unless bp_attrs[:executed_setup_multi_element_groups]
    bp_attrs[:executed_setup_multi_element_groups] = true
    MultiElementValue.delete_all
    MultiElementGroup.delete_all
    project_type_group = MultiElementGroup.create :name => 'project_types', :description => 'ProjectType', :target_class_name => 'Project'
    MultiElementValue.create :multi_element_group_id => project_type_group.id, :value => 'Program'
    MultiElementValue.create :multi_element_group_id => project_type_group.id, :value => 'IT'
    MultiElementValue.create :multi_element_group_id => project_type_group.id, :value => 'Grants'
    MultiElementValue.create :multi_element_group_id => project_type_group.id, :value => 'Finance'
    MultiElementValue.create :multi_element_group_id => project_type_group.id, :value => 'HR'
    MultiElementValue.create :multi_element_group_id => project_type_group.id, :value => 'All Staff'
    ProjectList.add_multi_elements

    # project list types 
    project_list_type_group = MultiElementGroup.create :name => 'list_types', :description => 'ListType', :target_class_name => 'ProjectList'
    MultiElementValue.create :multi_element_group_id => project_list_type_group.id, :value => 'Numbers'
    MultiElementValue.create :multi_element_group_id => project_list_type_group.id, :value => 'Bulleted'
    MultiElementValue.create :multi_element_group_id => project_list_type_group.id, :value => 'To-Do'
    Project.add_multi_elements
  end
end