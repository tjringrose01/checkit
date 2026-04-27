class PasswordResetVerificationsController < ApplicationController
  before_action :set_pending_user

  def show; end

  def create
    if @user.verify_password_reset_code!(verification_params[:code].to_s)
      session.delete(:pending_password_reset_user_id)
      session[:verified_password_reset_user_id] = @user.id
      redirect_to edit_password_reset_path, notice: "Verification complete. Set a new password."
    else
      flash.now[:alert] = "Verification could not be completed."
      render :show, status: :unprocessable_entity
    end
  end

  def resend
    unless @user.password_reset_resend_allowed?
      redirect_to password_reset_verification_path, alert: "A new code is not available yet."
      return
    end

    code = @user.prepare_password_reset!
    UserMailer.password_reset_verification(@user, code).deliver_now
    redirect_to password_reset_verification_path, notice: "A new verification code was sent."
  end

  private

  def set_pending_user
    @user = User.find_by(id: session[:pending_password_reset_user_id])
    return if @user&.password_reset_pending?

    redirect_to new_password_reset_request_path, alert: "There is no pending password reset verification."
  end

  def verification_params
    params.fetch(:password_reset_verification, {}).permit(:code)
  end
end
