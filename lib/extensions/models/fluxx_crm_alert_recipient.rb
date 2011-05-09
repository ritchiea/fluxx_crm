module FluxxCrmAlertRecipient
  extend FluxxModuleHelper

  when_included do
    belongs_to :user
    belongs_to :alert

    validates :alert, :presence => true
    validates :alert_id, :uniqueness => {:scope => :user_id}
  end
end
