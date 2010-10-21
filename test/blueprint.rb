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
  login Sham.login
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
  documentable User.make
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
  role_name 'create_organization'
  user_profile do
    UserProfile.make
  end
end