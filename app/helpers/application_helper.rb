module ApplicationHelper
  def can_current_user_edit_create_organizations?
    # TODO ESH: override in reference implemention to add check for the correct role
    true
  end
  
  def can_current_user_edit_create_users?
      # TODO ESH: override in reference implemention to add check for the correct role
      true
    end
  
  def link_to_delete label, model, options = {}, use_onclick=true
    options[:method] = :delete
    link_class = options.delete(:link_class)
    refresh_function = (options[:refresh] == :partial ? 'onCompleteRefreshPartial' : 'onCompleteRefresh')
    append_to = (options[:refresh] == :partial ? 'fluxxCardPartial' : 'fluxxCardArea')

    form = form_for(model, :html => options){|f| }
    form.gsub!('\n',' ');
    form = "$('#{raw form.to_s}').submit(#{refresh_function}).appendTo($(this).#{append_to}()).submit();return false;"

    raw link_to(label, model, :onclick => (
        use_onclick ? raw("if(confirm('This record will be deleted. Are you sure?')) {#{raw form.to_s}}; return false;") : "#{raw form.to_s}"), :class => link_class)
  end
  
  def link_to_update label, model, options = {}
    options[:method] = :put
    link_class = options.delete(:link_class)
    concat link_to(label, model, :onclick => "$(this).next().submit();return false;", :class => link_class)
    raw form_for model, :html => options do |form| 
      yield form
    end
  end

  def link_to_post label, model, url, options = {}
    options[:method] = :post
    options[:style] = 'display: none'
    link_class = options.delete(:link_class)
    concat link_to(label, url, :onclick => "$(this).next().submit();return false;", :class => link_class)
    raw form_for model, :url => url, :html => options do |form| 
      yield form
    end
  end
end
