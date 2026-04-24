class DashboardController < ApplicationController
  before_action :require_authentication
  before_action :require_password_change

  def show
    @checklists = Checklist.active.includes(checklist_items: :checklist_item_completions)
  end
end
