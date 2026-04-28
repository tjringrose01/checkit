class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params.merge(role: "user", must_change_password: false, enabled: true))
    @user.skip_initial_email_verification_default = true

    if @user.save
      code = @user.prepare_email_verification!
      UserMailer.registration_verification(@user, code).deliver_now
      session[:pending_verification_user_id] = @user.id
      redirect_to email_verification_path, notice: "Enter the verification code sent to your email."
    else
      flash.now[:alert] = "Registration could not be completed."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:first_name, :last_name, :user_id, :email, :password, :password_confirmation)
  end
end
