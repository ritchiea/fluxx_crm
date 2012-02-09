class ActiveRecord::ModelDslAlert < ActiveRecord::ModelDsl
  def self.trigger_and_mail_alerts_for controllers
    Alert.delay(:run_at => 1.minutes.from_now).trigger_and_mail_alerts_for controllers
  end
end