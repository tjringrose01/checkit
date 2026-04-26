module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show enable disable unlock reset_password destroy]

    def index
      @users = User.order(:role, :user_id)
      @locked_users = @users.select(&:locked?)
      @disabled_users = @users.reject(&:enabled?)
    end

    def show; end

    def enable
      @user.update!(enabled: true)

      redirect_to admin_user_path(@user), notice: "User enabled."
    end

    def disable
      return redirect_to admin_user_path(@user), alert: "You cannot disable your own account." if @user == current_user
      return redirect_to admin_user_path(@user), alert: "At least one admin account must remain enabled." if disabling_last_enabled_admin?(@user)

      @user.update!(enabled: false)

      redirect_to admin_user_path(@user), notice: "User disabled."
    end

    def unlock
      @user.unlock_access!
      UserMailer.account_unlocked(@user).deliver_now

      redirect_to admin_user_path(@user), notice: "User unlocked."
    end

    def reset_password
      if reset_password_params[:password].blank?
        return redirect_to admin_user_path(@user), alert: "Password cannot be blank."
      end

      if @user.update(reset_password_attributes)
        redirect_to admin_user_path(@user), notice: "User password reset."
      else
        redirect_to admin_user_path(@user), alert: @user.errors.full_messages.to_sentence
      end
    end

    def destroy
      return redirect_to admin_user_path(@user), alert: "You cannot delete your own account." if @user == current_user
      return redirect_to admin_user_path(@user), alert: "At least one admin account must remain." if deleting_last_admin?(@user)

      @user.destroy
      redirect_to admin_users_path, notice: "User deleted."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def reset_password_params
      params.require(:user).permit(:password, :password_confirmation)
    end

    def reset_password_attributes
      reset_password_params.merge(
        must_change_password: true,
        failed_login_attempts: 0,
        locked_at: nil
      )
    end

    def deleting_last_admin?(user)
      user.admin? && User.admin.where.not(id: user.id).none?
    end

    def disabling_last_enabled_admin?(user)
      user.admin? && user.enabled? && User.admin.where(enabled: true).where.not(id: user.id).none?
    end
  end
end
