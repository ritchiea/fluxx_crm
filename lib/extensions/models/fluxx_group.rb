module FluxxGroup
  def self.included(base)
    base.has_many :group_members
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.validates_length_of       :name,    :within => 2..250
    base.validates_uniqueness_of   :name
    base.before_destroy :delete_all_group_members
    
    base.insta_search

    base.insta_export

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    def all_sorted_groups
      Group.find(:all, :conditions => {:deprecated => false}).sort_by{|group| (group.name || '').downcase}
    end
    
    def load_all
      Group.find(:all).sort_by{|group| (group.name || '').downcase}
    end
  end

  module ModelInstanceMethods
    def update_related_data
      favorable.update_attribute :delta, 1 if favorable
    end

    def deletable?
      true
    end
    
    def number_of_associated_records
      group_members.count
    end
    
    def delete_all_group_members
      # Note: group_members.destroy_all will instantiate each group_member and call destroy on it, which is inefficient; but that is the way to go if you want to account for a ripple effect if other records need to be deleted as well.  "Instantiation, callback execution, and deletion of each record can be time consuming when you’re removing many records at once. It generates at least one SQL DELETE query per record (or possibly more, to enforce your callbacks). If you want to delete many rows quickly, without concern for their associations or callbacks, use delete_all instead."
      # Note: group_members.delete_all will set the group_id to null for any members that match the group_id, which is pretty useless
      GroupMember.delete_all ['group_id = ?', self.id] # This is straight SQL.  Note this does not update sphinx for the element associated with the group_member for performance reasons
    end
  end
end