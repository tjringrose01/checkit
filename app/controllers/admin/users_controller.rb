module Admin
  class UsersController < BaseController
    def unlock
      user = User.find(params[:id])
      user.unlock_access!
      UserMailer.account_unlocked(user).deliver_now

      redirect_to admin_root_path, notice: "User unlocked."
    end
  end
end
