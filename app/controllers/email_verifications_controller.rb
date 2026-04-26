class EmailVerificationsController < ApplicationController
  before_action :set_pending_user

  def show; end

  def create
    if @user.verify_email_code!(verification_params[:code].to_s)
      session.delete(:pending_verification_user_id)
      reset_session
      session[:user_id] = @user.id
      @user.record_successful_login!
      redirect_to root_path, notice: "Registration complete."
    else
      flash.now[:alert] = "Verification could not be completed."
      render :show, status: :unprocessable_entity
    end
  end

  def resend
    unless @user.verification_resend_allowed?
      redirect_to email_verification_path, alert: "A new code is not available yet."
      return
    end

    code = @user.prepare_email_verification!
    UserMailer.registration_verification(@user, code).deliver_now
    redirect_to email_verification_path, notice: "A new verification code was sent."
  end

  private

  def set_pending_user
    @user = User.find_by(id: session[:pending_verification_user_id])
    return if @user&.verification_pending?

    redirect_to new_session_path, alert: "There is no pending verification."
  end

  def verification_params
    params.fetch(:email_verification, {}).permit(:code)
  end
end
