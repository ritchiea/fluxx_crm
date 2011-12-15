module FluxxModelDocumentTemplate
  SEARCH_ATTRIBUTES = [:model_type]

  def self.included(base)
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.belongs_to :related_model_document_template, :class_name => 'ModelDocumentTemplate', :foreign_key => 'related_model_document_template_id'
    base.acts_as_audited({:full_model_enabled => false, :except => [:created_by_id, :updated_by_id, :delta, :updated_by, :created_by, :audits]})

    base.validates_presence_of :model_type
    base.validates_presence_of :description
    
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
    end
    base.insta_export
    base.insta_realtime
    base.insta_lock

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    def potential_parents
      ModelDocumentTemplate.where(:deleted_at => nil, :related_model_document_template_id => nil)
    end
    
    def for_type_and_category(model_type, category=nil)
      clause = where(:model_type => model_type, :deleted_at => nil)
      clause = clause.where(:category => category) if category
      clause.order('description')
    end
    
    def adhoc_for_type_and_category(model_type, category=nil)
      for_type_and_category(model_type, category).where(:display_in_adhoc_list => true)
    end
    
    # STOP! use only for dev purposes
    def reload_all_templated_model_documents
      ModelDocumentTemplate.reload_all_doc_templates

      ModelDocumentTemplate.connection.execute 'update model_documents, model_document_templates set model_documents.document_text = model_document_templates.document, model_documents.document_content_type = model_document_templates.document_content_type where model_documents.model_document_template_id = model_document_templates.id'
    end
    
    def reload_all_doc_templates
      ModelDocumentTemplate.all.each do |doc_template|
        doc_template.reload_from_file
      end
    end
  end

  module ModelInstanceMethods
    def to_s
      description
    end

    def reload_from_file
      possible_files = ActionController::Base.view_paths.map {|v| "#{v.instance_variable_get '@path'}/doc_templates/#{self.filename}"}
      filename = possible_files.map{|file_name| file_name if File.exist?(file_name) }.compact.first
      if filename
        p "Loading file #{filename}"
        doc_contents = File.open(filename, 'r').read_whole_file
        self.update_attribute :document, doc_contents
      end
    end
  end
end