class DashboardController < ApplicationController
  before_action :require_authentication
  before_action :require_password_change

  def index
    @checklists = Checklist.active.includes(:checklist_items)
  end

  def show
    @checklist = Checklist.active.includes(checklist_items: :checklist_item_completions).find(params[:id])
  end
end
