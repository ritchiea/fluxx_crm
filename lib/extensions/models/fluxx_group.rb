module FLuxxGroup
  def self.included(base)
    base.has_many :group_members
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :modified_by, :class_name => 'User', :foreign_key => 'modified_by_id'
    
    base.insta_search

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    def all_sorted_groups
      Group.find(:all, :conditions => {:deprecated => false}).sort_by{|group| group.name.downcase}
    end
  end

  module ModelInstanceMethods
    def update_related_data
      favorable.update_attribute :delta, 1 if favorable
    end
  end
end