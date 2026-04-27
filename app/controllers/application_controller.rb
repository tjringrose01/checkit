class ApplicationController < ActionController::Base
  helper_method :current_user, :authenticated?

  private

  def current_user
    return @current_user if defined?(@current_user)
    return @current_user = nil unless session[:user_id]

    @current_user = User.find_by(id: session[:user_id])
  end

  def authenticated?
    current_user.present?
  end

  def require_authentication
    return if authenticated?

    redirect_to new_session_path
  end

  def require_password_change
    return unless authenticated?
    return unless current_user.must_change_password?
    return if request.path == edit_password_change_path

    redirect_to edit_password_change_path, alert: "You must change your password before continuing."
  end

  def require_admin
    return if authenticated? && current_user.admin?

    redirect_to root_path, alert: "Administrator access is required."
  end
end
