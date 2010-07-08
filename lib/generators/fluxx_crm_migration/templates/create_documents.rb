class FluxxCrmCreateGeoCities < ActiveRecord::Migration
  def self.up
    create_table :geo_cities do |t|
      t.timestamps
      t.string :name, :limit => 150, :null => false
      t.integer :geo_state_id, :limit => 12, :null => true
      t.integer :country_id, :limit => 12, :null => true
      t.string :postalCode, :latitude, :longitude, :metro_code, :area_code, :limit => 150, :null => true
      t.integer :orginal_loc_id, :limit => 12, :null => false # The original record ID supplied by maxmind
    end
    add_foreign_key 'geo_cities', 'geo_state_id', 'geo_states', 'id', 'geo_cities_state_id'
    add_foreign_key 'geo_cities', 'country_id', 'countries', 'id', 'geo_cities_country_id'
    add_index :geo_cities, :name, :name => 'geo_cities_name_index'
  end

  def self.down
    drop_table :geo_cities
  end
end
