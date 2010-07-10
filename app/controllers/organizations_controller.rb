class OrganizationsController < ApplicationController
  insta_index Organization do |insta|
    insta.template = 'organization_list'
  end
  insta_show Organization do |insta|
    insta.template = 'organization_show'
  end
  insta_new Organization do |insta|
    insta.template = 'organization_form'
  end
  insta_edit Organization do |insta|
    insta.template = 'organization_form'
  end
  insta_post Organization do |insta|
    insta.template = 'organization_form'
  end
  insta_put Organization do |insta|
    insta.template = 'organization_form'
  end
  insta_delete Organization do |insta|
    insta.template = 'organization_form'
  end
  insta_related Organization do |insta|
    insta.add_related do |related|
      related.display_name = 'People'
      related.related_class = User
      related.search_id = :organization_id
      related.extra_condition = {:deleted_at => 0}
      related.max_results = 20
      related.order = 'last_name asc, first_name asc'
      related.display_template = '/users/related_users'
    end
  end
  
end