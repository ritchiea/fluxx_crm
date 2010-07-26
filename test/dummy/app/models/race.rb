class Race < ActiveRecord::Base
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'

  insta_workflow do |insta|
    insta.states_to_english = {:new => 'New', :beginning => 'Beginning', :middle => 'Middle', :final => 'Final'}
    insta.events_to_english = {:kick_off => 'Kick Off', :sprint => 'Sprint', :final_sprint => 'Final Sprint'}
  end
  insta_search
  
  include AASM

  aasm_column :state
  aasm_initial_state :new
  
  aasm_state :new
  aasm_state :beginning
  aasm_state :middle
  aasm_state :final
  
  aasm_event :kick_off do
    transitions :from => :new, :to => :beginning
  end

  aasm_event :sprint do
    transitions :from => :beginning, :to => :middle
  end

  aasm_event :final_sprint do
    transitions :from => :middle, :to => :final
  end
end
