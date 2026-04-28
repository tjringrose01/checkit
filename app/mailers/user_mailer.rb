class UserMailer < ApplicationMailer
  def registration_verification(user, code)
    @user = user
    @code = code

    mail(to: @user.email, subject: "Verify your Checkit account") do |format|
      format.text do
        render plain: <<~BODY
          Hello #{@user.user_id},

          Your Checkit verification code is #{@code}.

          Enter this code in the application to finish registering your account.
          The code expires in 15 minutes.
        BODY
      end
    end
  end

  def account_unlocked(user)
    @user = user

    mail(to: @user.email, subject: "Your Checkit account has been unlocked") do |format|
      format.text do
        render plain: <<~BODY
          Hello #{@user.user_id},

          Your Checkit account has been unlocked by an administrator.
          You can now sign in again with your user ID and password.
        BODY
      end
    end
  end

  def password_reset_verification(user, code)
    @user = user
    @code = code

    mail(to: @user.email, subject: "Verify your Checkit password reset") do |format|
      format.text do
        render plain: <<~BODY
          Hello #{@user.user_id},

          Your Checkit password reset verification code is #{@code}.

          Enter this code in the application before choosing a new password.
          The code expires in 15 minutes.
        BODY
      end
    end
  end
end
