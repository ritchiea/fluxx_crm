class ActiveRecord::ModelDslAlert < ActiveRecord::ModelDsl
  def self.trigger_and_mail_alerts_for controllers
    Alert.delay.trigger_and_mail_alerts_for controllers
  end
end