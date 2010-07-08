class GeoCity < ActiveRecord::Base
  belongs_to :geo_state
  belongs_to :geo_country
  acts_as_audited

  validates_presence_of :geo_state
  validates_presence_of :geo_country
  
  def to_s
    name
  end
end
