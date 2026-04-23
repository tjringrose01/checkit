class ChecklistItemCompletionsController < ApplicationController
  before_action :require_authentication
  before_action :require_password_change

  def update
    checklist_item = ChecklistItem.joins(:checklist).merge(Checklist.active).find(params[:checklist_item_id])
    completion = current_user.checklist_item_completions.find_or_initialize_by(checklist_item: checklist_item)
    completion.actual_completed_at = completed_param? ? Time.current : nil

    if completion.save
      redirect_to root_path, notice: "Checklist item updated."
    else
      redirect_to root_path, alert: completion.errors.full_messages.to_sentence
    end
  end

  private

  def completed_param?
    ActiveModel::Type::Boolean.new.cast(params[:completed])
  end
end
