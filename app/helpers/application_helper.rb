module ApplicationHelper
  def load_audits model
    model.audits.sort_by{|aud| aud.id * -1}
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

  def build_audit_table_and_summary model, audit
    reflections_by_fk = model.class.reflect_on_all_associations.inject({}) do |acc, ref|
      acc[ref.association_foreign_key] = ref if ref
      acc
    end
    reflections_by_name = model.class.reflect_on_all_associations.inject({}) do |acc, ref|
      acc[ref.name.to_s] = ref
      acc
    end
    audit_changes = audit.attributes['audit_changes']
    audit_summary = ''
    audit_summary += " By #{audit.user.full_name}" if audit.user
    audit_summary += " Modified at #{audit.created_at.ampm_time} on #{audit.created_at.full}" if audit.created_at
    audit_table = ''
    if audit_changes && audit_changes.is_a?(Hash)
      audit_table += "<table class='audit-detail'><tr><th class'attribute'>Attribute</th><th class='old'>Was</th><th class='arrow'>&nbsp;</th><th class='new'>Changed To</th></tr>"
      audit_changes.keys.each do |k|
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
            "<span class='empty'>empty</span>" 
          else
            old_value.to_s.humanize
          end
          new_value = if new_value.blank?
            "<span class='empty'>empty</span>"
          else
            new_value.to_s.humanize
          end
          audit_table += "<tr><td class='attribute'>#{k.to_s.humanize}</td><td class='old'>#{old_value}</td><td class='arrow'>&rarr;</td><td class='new'>#{new_value}</td></tr>"
          
        end
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
      ['Email Address:', model.email ],
      ['Personal Phone:', model.personal_phone ],
      ['Personal Mobile:', model.personal_mobile ],
      ['Personal Fax:', model.personal_fax ],
      ['Personal Blog:', model.blog_url ],
      ['Personal Twitter:', model.twitter_url ],
      ['Assistant Name:', model.assistant_name ],
      ['Assistant Phone:', model.assistant_phone ],
      ['Assisant Email:', model.assistant_email ],
    ]
  end
end
