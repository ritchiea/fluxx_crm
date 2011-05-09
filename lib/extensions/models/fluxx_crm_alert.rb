module FluxxCrmAlert
  extend FluxxModuleHelper

  when_included do
    has_many :alert_recipients
    belongs_to :alert_email_template
  end

  class_methods do
    def with_triggered_alerts!(&alert_processing_block)
      Alert.find_each do |alert|
        matching_rtus = []
        last_realtime_update_id = alert.last_realtime_update_id
        RealtimeUpdate.where("id > ?", alert.last_realtime_update_id).order('id asc').find_each do |rtu|
          last_realtime_update_id = rtu.id
          matching_rtus << alert.should_be_triggered?(rtu)
        end

        alert.update_attribute(:last_realtime_update_id, last_realtime_update_id)
        alert_processing_block.call(alert, matching_rtus) unless matching_rtus.empty?
      end
    end
  end

  instance_methods do
    def should_be_triggered?(rtu)
      filter.matches?(rtu)
    end

    def recipients(rtu)
      alert_recipients.map do |alert_recipient|
        if alert_recipient.user
          alert_recipient.user
        else
          user_id = rtu.model.send(alert_recipient.rtu_model_user_method)
          User.find(user_id)
        end
      end.uniq
    end

    def to_liquid
      {}
    end

    def subject(locals={})
      Liquid::Template.parse(alert_email_template.subject).render(locals.stringify_keys.merge('alert' => self))
    end

    def body(locals={})
      Liquid::Template.parse(alert_email_template.body).render(locals.stringify_keys.merge('alert' => self))
    end

    def filter=(rtu_matcher)
      @filter = rtu_matcher
      write_attribute(:filter, @filter.to_json)
    end

    def filter
      @filter ||= RTUMatcher.from_json(read_attribute(:filter))
    end
  end
end
