class PasswordResetsController < ApplicationController
  before_action :set_verified_user

  def edit; end

  def update
    if @user.update(password_reset_params)
      @user.clear_password_reset_state!
      @user.unlock_access!
      @user.update_column(:must_change_password, false)
      session.delete(:verified_password_reset_user_id)
      redirect_to new_session_path, notice: "Password updated. You can sign in now."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_verified_user
    @user = User.find_by(id: session[:verified_password_reset_user_id])
    return if @user&.password_reset_eligible?

    redirect_to new_password_reset_request_path, alert: "Password reset verification is required."
  end

  def password_reset_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
