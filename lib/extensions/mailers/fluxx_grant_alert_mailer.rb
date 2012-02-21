module FluxxCrmAlertMailer
  extend FluxxModuleHelper
  
  when_included do
    default :return_path => 'system@fluxxlabs.com'
  end

  instance_methods do
    def from_email_address
      Fluxx.config(:from_email_address) || 'do-not-reply@fluxxlabs.com'
    end
    
    def alert(recipient, alert, locals={})
      mail(:from => from_email_address, :reply_to => from_email_address, :to => recipient.is_a?(User) ? recipient.mailer_email : recipient.to_s, 
           :cc => alert.cc_emails, :bcc => alert.bcc_emails,
           :subject => alert.liquid_subject(locals.merge('recipient' => recipient))) do |format|
             format.html { render :text => alert.liquid_body(locals.merge('recipient' => recipient)) }
      end
    end
    
    def alert_grouped(recipient, alert, locals={})
      
      mail(:from => from_email_address, :reply_to => from_email_address, :to => recipient.is_a?(User) ? recipient.mailer_email : recipient.to_s,
           :subject => alert.liquid_subject(locals.merge('recipient' => recipient))) do |format|
             format.html { render :text => alert.liquid_body(locals.merge('recipient' => recipient)) }
      end
    end
  end
end
