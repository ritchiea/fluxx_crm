class GeoCountry < ActiveRecord::Base
  has_many :geo_states
  acts_as_audited
end
