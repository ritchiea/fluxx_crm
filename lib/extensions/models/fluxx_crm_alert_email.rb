module FluxxCrmAlertEmail
  extend FluxxModuleHelper

  when_included do
    belongs_to :alert
    belongs_to :model, :polymorphic => true

    before_create :set_send_at
  end

  class_methods do
    def enqueue(method, attrs={})
      alert = attrs[:alert]
      if alert.group_models
        # In the case of sending alerts for a particular user, we group the models and send them all at once
        model = attrs[:model]
        create(attrs.merge(:mailer_method => method.to_s))
      else
        # In the case of sending alerts to users related to an email, we send an alert per model as the recipient may change
        model = attrs[:model]

        if !there_are_undelivered_alerts_with(alert, model) && no_previous_time_based_email_exist_for(alert, model)
          create(attrs.merge(:mailer_method => method.to_s, :model => model))
        end
      end
    end

    def no_previous_time_based_email_exist_for(alert, model)
      !alert.has_time_based_filtered_attrs? || !where(:alert_id => alert.id, :model_id => model.id, :model_type => model.class).exists?
    end

    def there_are_undelivered_alerts_with(alert, model)
      where(:delivered => false, :alert_id => alert.id, :model_id => model.id, :model_type => model.class).exists?
    end

    def deliver_all
      pending_deliver.each(&:deliver)
    end

    def pending_deliver
      where(["delivered = ? AND (send_at <= ? OR send_at IS NULL)", false, DateTime.now])
    end

    def minimum_time_between_emails
      1.day
    end
  end

  instance_methods do
    def deliver
      alert.model_recipients(model).each do |recipient| 
        begin
          if alert.group_models
            email_params_from_json = self.email_params.de_json if self.email_params
            models = if email_params_from_json && alert.controller_klass && alert.controller_klass.class_index_object
              alert.controller_klass.class_index_object.model_class.where({:id => email_params_from_json['models']}).all
            end
            
            AlertMailer.send(mailer_method, recipient, alert, "models" => models).deliver
          else
            AlertMailer.send(mailer_method, recipient, alert, "model" => model).deliver
          end
        rescue Exception => e
          HoptoadNotifier.notify(:error_message => "Unable to deliver email for recipient #{recipient.id} for alert_email=#{self.id}, #{e.inspect}, trace: #{e.backtrace.inspect}")
        end

      end
      update_attributes(:delivered => true)
    end

    def set_send_at
      last_matching_delivered_alert = self.class.where(:delivered => true, :alert_id => alert.id, :model_id => model.id, :model_type => model.class).order("send_at ASC").last
      self.send_at = if last_matching_delivered_alert && last_matching_delivered_alert.send_at
        last_matching_delivered_alert.send_at + self.class.minimum_time_between_emails
      else
        DateTime.now
      end
    end
  end
end
