class SessionsController < ApplicationController
  def new
    return unless authenticated?

    if current_user.must_change_password?
      redirect_to edit_password_change_path
    else
      redirect_to root_path
    end
  end

  def create
    user = User.find_by(user_id: normalized_user_id)

    if user && !user.enabled_for_authentication?
      redirect_to new_session_path, alert: "Invalid credentials or account unavailable."
      return
    end

    if user&.locked?
      handle_failed_authentication(user)
      return
    end

    if user&.authenticate(params[:password].to_s)
      complete_login(user)
    else
      handle_failed_authentication(user)
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Signed out."
  end

  private

  def normalized_user_id
    params[:user_id].to_s.strip.downcase
  end

  def complete_login(user)
    reset_session
    session[:user_id] = user.id
    user.record_successful_login!

    if user.must_change_password?
      redirect_to edit_password_change_path, notice: "Update your password to continue."
    else
      redirect_to root_path, notice: "Signed in."
    end
  end

  def handle_failed_authentication(user)
    user&.record_failed_login!
    redirect_to new_session_path, alert: "Invalid credentials or account unavailable."
  end
end
