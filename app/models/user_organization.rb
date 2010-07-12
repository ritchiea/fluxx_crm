class UserOrganization < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization
  belongs_to :locked_by, :class_name => 'User', :foreign_key => 'locked_by_id'
  acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta]})
  
  validates_presence_of :user_id
  validates_presence_of :organization_id
  validates_uniqueness_of :organization_id, :scope => :user_id
end