module ApplicationHelper
  USE_S3 = defined?(USE_MODEL_DOCUMENT_S3) && USE_MODEL_DOCUMENT_S3
  
  def s3_or_file_path model_document
    client_id = defined?(Client) ? Client.current_client_id : 0
    if USE_S3
      "/s3/#{client_id}/#{model_document.id}"
    else
      model_document.document.url
    end
  end
  
  def urlencode_filename(path)
    require 'cgi'
    fname, timestamp = path.split(/\?(\d+)/)
    [fname.split("/").map { |part| CGI::escape(part) }.join("/"), timestamp].join("?")
  end

  def dollars_format amount
    number_to_currency amount, :precision => 0
  end

  def mdy_date_format value
    (value && value.is_a?(Time)) ? value.mdy : value
  end

  def show_path_for_model model, options={}
    send("#{model.class.calculate_form_name.to_s}_path", options)
  end

  def plural_by_list list, singular, plural=nil
    count = list ? list.size : 0
    ((count == 1) ? singular : (plural || singular.pluralize))
  end

  # This method demonstrates the use of the :child_index option to render a
  # form partial for, for instance, client side addition of new nested
  # records.
  #
  # This specific example creates a link which uses javascript to add a new
  # form partial to the DOM.
  #
  #   <% form_for @project do |project_form| -%>
  #     <div id="tasks">
  #       <% project_form.fields_for :tasks do |task_form| %>
  #         <%= render :partial => 'task', :locals => { :f => task_form } %>
  #       <% end %>
  #     </div>
  #   <% end -%>
  # Citation: http://github.com/alloy/complex-form-examples
  def generate_html(form_builder, method, options = {})
    options[:object] ||= form_builder.object.class.reflect_on_association(method).klass.new
    options[:partial] ||= method.to_s.singularize
    options[:form_builder_local] ||= :f

    form_builder.fields_for(method, options[:object], :child_index => '{{ record_index }}') do |f|
      render(:partial => options[:partial], :locals => { options[:form_builder_local] => f })
    end
  end

  def generate_template(form_builder, method, options = {})
    escape_carriage_returns(single_quote_html(generate_html(form_builder, method, options)))
  end

  def single_quote_html html
    html.gsub '"', "'"
  end

  def escape_carriage_returns html
    html.gsub "\n", '\\n'
  end

  # Note: we cannot count on audits to be in numerically ascending order by id; use created_at instead
  def load_audits model
    model.audits.includes(:user).sort_by{|aud| [aud.created_at.to_i * -1, aud.id * -1]}
  end
  
  # Convert mime type to a class that can be used 
  def mime_type_to_class mime_type
    return 'file-type file-type-file' unless mime_type
    if mime_type.index('image') == 0
      'file-type file-type-image'
    elsif mime_type.index('audio') == 0
      'file-type file-type-audio'
    elsif mime_type.index('video') == 0
      'file-type file-type-video'
    elsif mime_type.index('application') == 0
      if mime_type.index('msword') || mime_type.index('officedocument.wordprocessing')
        'file-type file-type-word'
      elsif mime_type.index('vnd.ms-excel')
        'file-type file-type-excel'
      elsif mime_type.index('powerpoint') || mime_type.index('officedocument.presentation')
        'file-type file-type-powerpoint'
      elsif mime_type.index('pdf')
        'file-type file-type-pdf'
      else
        'file-type file-type-file'
      end
    else  
      'file-type file-type-file'
    end  
  end

  def collect_audits model, audits
    reflections_by_fk = calculate_reflections_by_fk model
    reflections_by_name = calculate_reflections_by_name model
    
    audits.map do |audit|
      {:audit => audit, :deltas => calculate_audit_changes(model, audit, reflections_by_fk, reflections_by_name)}
    end
  end
  
  def calculate_reflections_by_fk model
    reflections_by_fk = model.class.reflect_on_all_associations.inject({}) do |acc, ref|
      acc[ref.association_foreign_key] = ref if ref
      acc
    end
  end
  def calculate_reflections_by_name model
    reflections_by_name = model.class.reflect_on_all_associations.inject({}) do |acc, ref|
      acc[ref.name.to_s] = ref
      acc
    end
  end
  
  ATTRIBUTE_NAMES_TO_FILTER = ['last_logged_in_at', 'time_zone', 'locked_until', 'locked_by_id', 'crypted_password', 'password_salt', 'persistence_token', 'single_access_token', 'confirmation_sent_at', 'login_count', 'failed_login_count', 'current_login_at', 'last_login_at', 'current_login_ip', 'last_login_ip', 'user_profile_id', 'test_user_flag', 'deleted_at']
  def calculate_audit_changes model, audit, reflections_by_fk=nil, reflections_by_name=nil
    reflections_by_fk = calculate_reflections_by_fk(model) unless reflections_by_fk
    reflections_by_name = calculate_reflections_by_name(model) unless reflections_by_name
    audit_changes = audit.attributes['audit_changes'] || {}
    deltas = if audit_changes.is_a?(Hash)
      audit_changes.keys.map do |k|
        name = ''
        old_value = ''
        new_value = ''
        change = audit_changes[k]
        unless !change.is_a?(Array) || (change.first.blank? && change.second.blank?)
          k_name = k.gsub /_id$/, ''
          old_value, new_value = if reflections_by_fk[k] || reflections_by_name[k_name]
            klass = if reflections_by_fk[k]
              reflections_by_fk[k].class_name.constantize
            else
              reflections_by_name[k_name].class_name.constantize
            end
            old_obj = klass.find(change[0]) rescue nil
            new_obj = klass.find(change[1]) rescue nil
            [(old_obj.respond_to?(:name) ? old_obj.name : old_obj.to_s),
             (new_obj.respond_to?(:name) ? new_obj.name : new_obj.to_s)]
          else
            [change[0], change[1]]
          end
          old_value = if old_value.blank?
            nil
          else
            old_value.to_s.humanize
          end
          new_value = if new_value.blank?
            nil
          else
            new_value.to_s.humanize
          end
          name = k.to_s.humanize
        end
        {:name => name, :old_value => old_value, :new_value => new_value} unless name.blank? || ATTRIBUTE_NAMES_TO_FILTER.include?(k.to_s)
      end.compact
    else
      []
    end
  end

  def build_audit_table_and_summary model, audit, deltas
    audit_changes = audit.attributes['audit_changes']
    audit_summary = ''
    audit_summary += " By #{audit.user.full_name}" if audit.user
    audit_summary += " Modified at #{audit.created_at.ampm_time} on #{audit.created_at.full}" if audit.created_at
    audit_table = ''
    if audit.action == 'create'
      audit_table += "<div class='audit-detail'><p><strong>New Record Created</strong></div>"
    elsif deltas
      audit_table += "<table class='audit-detail'><tr><th class'attribute'>Attribute</th><th class='old'>Was</th><th class='arrow'>&nbsp;</th><th class='new'>Changed To</th></tr>"
      deltas.each do |delta|
        name = delta[:name]
        old_value = delta[:old_value]
        new_value = delta[:new_value]
        old_value = if old_value.blank?
          "<span class='empty'>empty</span>" 
        else
          old_value.to_s.humanize
        end
        new_value = if new_value.blank?
          "<span class='empty'>empty</span>"
        else
          new_value.to_s.humanize
        end
        audit_table += "<tr><td class='attribute'>#{name}</td><td class='old'>#{old_value}</td><td class='arrow'>&rarr;</td><td class='new'>#{new_value}</td></tr>"
      end
      audit_table += "</table>"
    end
    [audit_summary, audit_table]
  end
  
  def build_user_work_contact_details primary_user_org, model
    [
      ['Office Phone:', primary_user_org && primary_user_org.organization ? primary_user_org.organization.phone : nil ],
      ['Office Fax:', primary_user_org && primary_user_org.organization ? primary_user_org.organization.fax : nil ],
      ['Direct Phone:', model.work_phone],
      ['Direct Fax:', model.work_fax],
      ['Email Address:', email_link(model.email) ],
      ['Personal Phone:', model.personal_phone ],
      ['Personal Mobile:', model.personal_mobile ],
      ['Personal Fax:', model.personal_fax ],
      ['Personal Blog:', external_link(model.blog_url) ],
      ['Personal Twitter:', external_link(model.twitter_url) ],
      ['Assistant Name:', model.assistant_name ],
      ['Assistant Phone:', model.assistant_phone ],
      ['Assisant Email:', email_link(model.assistant_email) ],
    ]
  end

  def render_alert_field(field, options = {}, &block)
    if field.blank?
      options.fetch(:empty, "Any")
    else
      field.map(&block).join(options.fetch(:join, " or ")) unless field.blank?
    end
  end
end
