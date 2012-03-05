class NutCracker < ActiveRecord::Base
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'

  insta_workflow
  include AASM

  aasm_column :state
  aasm_initial_state :new
  
  aasm_state :new
end
