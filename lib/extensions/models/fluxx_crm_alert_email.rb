module FluxxCrmAlertEmail
  extend FluxxModuleHelper

  when_included do
    belongs_to :alert
    belongs_to :model, :polymorphic => true

    before_create :set_send_at
  end

  class_methods do
    def enqueue(method, attrs={})
      create(attrs.merge(:mailer_method => method.to_s))
    end

    def deliver_all
      undelivered.each(&:deliver)
    end

    def undelivered
      where(:delivered => false)
    end

    def minimum_time_between_emails
      1.day
    end
  end

  instance_methods do
    def deliver
      alert.model_recipients(model).each{|recipient| AlertMailer.send(mailer_method, recipient, alert, "model" => model).deliver}
      update_attributes(:delivered => true)
    end

    def set_send_at
      last_matching_delivered_alert = self.class.where(:delivered => true, :alert_id => alert.id, :model_id => model.id, :model_type => model.class).order("send_at ASC").last
      self.send_at = if last_matching_delivered_alert && last_matching_delivered_alert.send_at
        last_matching_delivered_alert.send_at + self.class.minimum_time_between_emails
      else
        Date.today
      end
    end
  end
end
