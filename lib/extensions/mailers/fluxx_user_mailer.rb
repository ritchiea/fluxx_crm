module FluxxUserMailer
  extend FluxxModuleHelper

  instance_methods do
    def forgot_password(user, reset_link)
      from          (defined?(DEFAULT_EMAIL_SENDER) && DEFAULT_EMAIL_SENDER ? DEFAULT_EMAIL_SENDER : 'do-not-reply@fluxxlabs.com')

      @reset_password_link = reset_link

      mail(:to => user.mailer_email,
           :subject => "Password Reset",
           :from => from,
           :fail_to => from
      ) do |format|
        format.text
      end
    end
    
    def new_user(user)
      from          (defined?(DEFAULT_EMAIL_SENDER) && DEFAULT_EMAIL_SENDER ? DEFAULT_EMAIL_SENDER : 'do-not-reply@fluxxlabs.com')

      @fluxx_link = FluxxManageHost.current_host
      @new_user = user

      mail(:to => user.mailer_email,
           :subject => "New User Information",
           :from => from,
           :fail_to => from
      ) do |format|
        format.text
      end
      
    end
    
  end
end
