module FluxxOrganizationsController
  ICON_STYLE = 'style-organizations'
  def self.included(base)
    base.insta_index Organization do |insta|
      insta.template = 'organization_list'
      insta.filter_template = 'organizations/organization_filter'
      insta.order_clause = 'name asc'
      insta.search_conditions = {:parent_org_id => nil}
      insta.icon_style = ICON_STYLE
      insta.create_link_title = "New Organization"
    end
    base.insta_show Organization do |insta|
      insta.template = 'organization_show'
      insta.icon_style = ICON_STYLE
      insta.format do |format|
        format.html do |triple|
          controller_dsl, outcome, default_block = triple
          if params[:satellites] == '1'
            send :fluxx_show_card, controller_dsl, {:template => 'organizations/organization_satellites', :footer_template => 'insta/simple_footer', :layout => false}
          else
            default_block.call
          end
        end
      end
    end
    base.insta_new Organization do |insta|
      insta.template = 'organization_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit Organization do |insta|
      insta.template = 'organization_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_post Organization do |insta|
      insta.template = 'organization_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_put Organization do |insta|
      insta.template = 'organization_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_delete Organization do |insta|
      insta.template = 'organization_form'
      insta.icon_style = ICON_STYLE
    end
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    ORG_QUERY_SELECT = "select organizations.id, soundex(name) name_soundex, soundex(street_address) street_soundex, 
      name, street_address, street_address2, city, 
      (select name from geo_states where id = geo_state_id) geo_state_name,
      (select name from geo_countries where id = geo_country_id) geo_country_name, postal_code, phone, fax, email, url, acronym"

    def dedupe_list
      @organizations = Organization.connection.execute "#{ORG_QUERY_SELECT}
        from organizations where deleted_at is null order by name_soundex, street_soundex"
      render :layout => false
    end
    
    def dedupe_prep
      @organizations = Organization.connection.execute ClientStore.send(:sanitize_sql, ["#{ORG_QUERY_SELECT}
        from organizations where id in (?) and deleted_at is null", params[:org_id]])
      render :action => 'dedupe_prep', :layout => false
    end
    
    def dedupe_complete
      @organizations = Organization.where(:id => params[:org_id], :deleted_at => nil).all
      @primary_org = Organization.where(:id => params[:primary_org_id], :deleted_at => nil).first
      if @organizations && @primary_org
        (@organizations - [@primary_org]).each do |dupe_org|
          p "ESH: merging dupe_org #{dupe_org.id} into primary_org #{@primary_org.id}"
          @primary_org.merge dupe_org
        end
        # TODO ESH: swap this out when it runs inside fluxx
        # fluxx_redirect organizations_dedupe_path
        redirect_to organizations_dedupe_path
      else
        dedupe_prep
      end
    end
  end
end