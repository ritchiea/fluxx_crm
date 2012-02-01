module FluxxUserMailer
  extend FluxxModuleHelper

  instance_methods do
    def from_email_address
      Fluxx.config(:from_email_address)
    end
    
    def forgot_password(user, reset_link)
      @reset_password_link = reset_link

      mail(:to => user.mailer_email,
           :subject => "Password Reset",
           :from => 'do-not-reply@fluxxlabs.com', :reply_to => from_email_address,
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
           :from => 'do-not-reply@fluxxlabs.com', :reply_to => from_email_address,
           :fail_to => from
      ) do |format|
        format.text
      end
      
    end
    
  end
end
