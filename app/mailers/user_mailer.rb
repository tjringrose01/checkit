class UserMailer < ApplicationMailer
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
end
