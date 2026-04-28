module Admin
  class DashboardController < BaseController
    def show
      @checklists = Checklist.includes(:checklist_items).order(:title)
      @locked_users = User.where.not(locked_at: nil).order(:user_id)
    end
  end
end
