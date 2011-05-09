module FluxxCrmAlertMailer
  extend FluxxModuleHelper

  instance_methods do
    def alert(recipient, alert, locals={})
      mail(:to => recipient.is_a?(String) ? recipient : recipient.email,
           :subject => alert.subject('recipient' => recipient),
           :body => alert.body('recipient' => recipient))
    end
  end
end
