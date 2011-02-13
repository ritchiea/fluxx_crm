module FluxxUserProfile
  def self.included(base)
    
    base.has_many :user_profile_rules
    base.insta_search do |insta|
      insta.really_delete = true
    end

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def has_rule? permission_name, model_type
      self.user_profile_rules.select {|rule| rule.permission_name == permission_name && rule.model_type == model_type}.first
    end
  end
end