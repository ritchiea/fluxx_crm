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
    def has_rule? role_name
      !self.user_profile_rules.select {|rule| rule.role_name = role_name}.empty?
    end
  end
end