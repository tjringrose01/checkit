class ChecklistResetsController < ApplicationController
  before_action :require_authentication
  before_action :require_password_change

  def update
    checklist = Checklist.active.find(params[:checklist_id])
    completions = current_user.checklist_item_completions.joins(:checklist_item).where(checklist_items: { checklist_id: checklist.id })
    completions.destroy_all

    respond_to do |format|
      format.html { redirect_to checklist_path(checklist), notice: "Checklist reset." }
      format.json { render json: { success: true } }
    end
  end
end
