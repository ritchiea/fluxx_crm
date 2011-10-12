module FluxxCrmAlertRecipient
  extend FluxxModuleHelper

  when_included do
    belongs_to :user
    belongs_to :alert

    validates :alert, :presence => true

    acts_as_audited({:full_model_enabled => false, :except => [:type, :last_realtime_update_id]})
  end
end
