module FluxxCrmAlertMailer
  extend FluxxModuleHelper

  instance_methods do
    def alert(recipient, alert, locals={})
      mail(:to => recipient.is_a?(String) ? recipient : recipient.email,
           :subject => alert.liquid_subject('recipient' => recipient),
           :body => alert.liquid_body('recipient' => recipient))
    end
  end
end
