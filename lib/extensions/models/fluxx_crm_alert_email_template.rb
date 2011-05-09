module FluxxCrmAlertEmailTemplate
  extend FluxxModuleHelper

  when_included do
    validates :subject, :presence => true
    validates :body, :presence => true
  end
end
