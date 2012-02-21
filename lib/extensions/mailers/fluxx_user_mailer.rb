module FluxxUserMailer
  extend FluxxModuleHelper

  when_included do
    default :return_path => 'system@fluxxlabs.com'
  end

  instance_methods do
    def from_email_address
      Fluxx.config(:from_email_address) || 'do-not-reply@fluxxlabs.com'
    end
    
    def forgot_password(user, reset_link)
      @reset_password_link = reset_link

      mail(:to => user.mailer_email,
           :subject => "Password Reset",
           :from => from_email_address, :reply_to => from_email_address,
           :fail_to => from
      ) do |format|
        format.text
      end
    end
    
    def new_user(user)
      @fluxx_link = FluxxManageHost.current_host
      @new_user = user

      mail(:to => user.mailer_email,
           :subject => "New User Information",
           :from => from_email_address, :reply_to => from_email_address,
           :fail_to => from
      ) do |format|
        format.text
      end
      
    end
    
  end
end
