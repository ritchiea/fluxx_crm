class Note < ActiveRecord::Base
  validates_presence_of     :note
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
  belongs_to :notable, :polymorphic => true
  acts_as_audited({:full_model_enabled => false, :except => [:created_by_id, :updated_by_id, :locked_until, :locked_by_id, :delta]})
  
  insta_realtime do |insta|
    insta.delta_attributes = [:updated_at, :notable_id, :notable_type]
    insta.updated_by_id = :updated_by_id
  end
end
