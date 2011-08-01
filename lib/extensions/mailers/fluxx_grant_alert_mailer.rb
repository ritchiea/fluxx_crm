module FluxxCrmAlertMailer
  extend FluxxModuleHelper

  instance_methods do
    def alert(recipient, alert, locals={})
      mail(:from => (defined?(DEFAULT_EMAIL_SENDER) && DEFAULT_EMAIL_SENDER ? DEFAULT_EMAIL_SENDER : 'do-not-reply@fluxxlabs.com'), :to => recipient.is_a?(User) ? recipient.mailer_email : recipient.to_s,
           :subject => alert.liquid_subject(locals.merge('recipient' => recipient))) do |format|
             format.html { render :text => alert.liquid_body(locals.merge('recipient' => recipient)) }
      end
    end
    
    def alert_grouped(recipient, alert, locals={})
      
      mail(:from => (defined?(DEFAULT_EMAIL_SENDER) && DEFAULT_EMAIL_SENDER ? DEFAULT_EMAIL_SENDER : 'do-not-reply@fluxxlabs.com'), :to => recipient.is_a?(User) ? recipient.mailer_email : recipient.to_s,
           :subject => alert.liquid_subject(locals.merge('recipient' => recipient))) do |format|
             format.html { render :text => alert.liquid_body(locals.merge('recipient' => recipient)) }
      end
    end
  end
end
