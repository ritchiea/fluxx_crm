class GeoState < ActiveRecord::Base
  belongs_to :geo_country
  has_many :geo_cities
  acts_as_audited

  validates_presence_of :geo_country
  
  def to_s
    name
  end
end
