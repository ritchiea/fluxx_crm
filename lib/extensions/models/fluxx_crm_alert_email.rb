module FluxxCrmAlertEmail
  extend FluxxModuleHelper

  when_included do
    belongs_to :alert
    belongs_to :realtime_update
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
  end

  instance_methods do
    def deliver
      alert.recipients(realtime_update).each{|recipient| AlertMailer.send(mailer_method, recipient, alert).deliver}
      update_attributes(:delivered => true)
    end
  end
end
