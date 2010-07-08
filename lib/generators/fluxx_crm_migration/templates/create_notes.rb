class FluxxCrmCreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      t.timestamps
      t.integer :created_by_id, :updated_by_id, :null => true, :limit => 12
      t.text :note, :null => false
      t.string :notable_type, :null => false
      t.integer :notable_id, :null => false, :limit => 12
      t.boolean :delta,                      :null => :false, :default => true
      t.datetime :deleted_at,                :null => true
    end
    add_foreign_key 'notes', 'created_by_id', 'users', 'id', 'notes_created_by_id'
    add_foreign_key 'notes', 'updated_by_id', 'users', 'id', 'notes_updated_by_id'
  end

  def self.down
    drop_table :notes
  end
end
