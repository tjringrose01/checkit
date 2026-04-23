class PasswordChangesController < ApplicationController
  before_action :require_authentication

  def edit; end

  def update
    unless current_user.authenticate(password_change_params[:current_password].to_s)
      flash.now[:alert] = "Current password is incorrect."
      render :edit, status: :unprocessable_entity
      return
    end

    if current_user.update(password_update_attributes)
      current_user.update_column(:must_change_password, false)
      redirect_to root_path, notice: "Password updated."
    else
      flash.now[:alert] = "Password could not be updated."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_change_params
    params.require(:password_change).permit(:current_password, :password, :password_confirmation)
  end

  def password_update_attributes
    password_change_params.except(:current_password)
  end
end
