class PasswordResetRequestsController < ApplicationController
  def new; end

  def create
    user = User.find_by(user_id: normalized_user_id, email: normalized_email)

    unless user&.password_reset_eligible?
      redirect_to new_password_reset_request_path, alert: "Password reset is not available for that account."
      return
    end

    code = user.prepare_password_reset!
    UserMailer.password_reset_verification(user, code).deliver_now
    session[:pending_password_reset_user_id] = user.id
    session.delete(:verified_password_reset_user_id)
    redirect_to password_reset_verification_path, notice: "Enter the verification code sent to your email."
  end

  private

  def normalized_user_id
    password_reset_request_params[:user_id].to_s.strip.downcase
  end

  def normalized_email
    password_reset_request_params[:email].to_s.strip.downcase
  end

  def password_reset_request_params
    params.fetch(:password_reset_request, {}).permit(:user_id, :email)
  end
end
