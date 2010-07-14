module FLuxxUsersController
  def self.included(base)
    base.insta_index User do |insta|
      insta.template = 'user_list'
    end
    base.insta_show User do |insta|
      insta.template = 'user_show'
    end
    base.insta_new User do |insta|
      insta.template = 'user_form'
    end
    base.insta_edit User do |insta|
      insta.template = 'user_form'
    end
    base.insta_post User do |insta|
      insta.template = 'user_form'
    end
    base.insta_put User do |insta|
      insta.template = 'user_form'
    end
    base.insta_delete User do |insta|
      insta.template = 'user_form'
    end

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
  end
end