module FluxxCrmAlertMailer
  extend FluxxModuleHelper
  
  instance_methods do
    def reply_to_email_address
      Fluxx.config(:replyto_email_address) || 'system@fluxx.io'
    end
    def return_path_email
      from_email = if Fluxx.config(:from_email_name)
        "<#{Fluxx.config(:from_email_name)}>"
      else
        ''
      end
      "#{from_email} system@fluxxlabs.com"
    end

    def from_email_address
      Fluxx.config(:from_email_address) || 'do-not-reply@fluxxlabs.com'
    end
    
    def alert(recipient, alert, locals={})
      @return_path = return_path_email
      mail(:from => return_path_email, :reply_to => from_email_address, :to => recipient.is_a?(User) ? recipient.mailer_email : recipient.to_s, 
           :cc => alert.cc_emails, :bcc => alert.bcc_emails,
           :subject => alert.liquid_subject(locals.merge('recipient' => (recipient.respond_to?(:user) ? recipient.user : recipient)))) do |format|
             format.html { render :text => alert.liquid_body(locals.merge('recipient' => recipient)) }
      end
    end
    
    def alert_grouped(recipient, alert, locals={})
      @return_path = return_path_email
      
      mail(:from => return_path_email, :reply_to => from_email_address, :to => recipient.is_a?(User) ? recipient.mailer_email : recipient.to_s,
           :subject => alert.liquid_subject(locals.merge('recipient' => (recipient.respond_to?(:user) ? recipient.user : recipient)))) do |format|
             format.html { render :text => alert.liquid_body(locals.merge('recipient' => recipient)) }
      end
    end
  end
end
