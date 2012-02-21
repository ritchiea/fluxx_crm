module FluxxUserMailer
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
    
    def forgot_password(user, reset_link)
      @reset_password_link = reset_link
      @return_path = return_path_email

      mail(:to => user.mailer_email,
           :subject => "Password Reset",
           :from => return_path_email, :reply_to => reply_to_email_address,
           :fail_to => from
      ) do |format|
        format.text
      end
    end
    
    def new_user(user)
      @fluxx_link = FluxxManageHost.current_host
      @return_path = return_path_email
      @new_user = user

      mail(:to => user.mailer_email,
           :subject => "New User Information",
           :from => return_path_email, :reply_to => reply_to_email_address,
           :fail_to => from
      ) do |format|
        format.text
      end
      
    end
    
  end
end
