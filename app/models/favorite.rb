class Favorite < ActiveRecord::Base
  belongs_to :favorable, :polymorphic => true
  belongs_to :user
  
  after_commit :update_related_data
  def update_related_data
    favorable.update_attribute :delta, 1 if favorable
  end
end
