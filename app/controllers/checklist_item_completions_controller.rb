class ChecklistItemCompletionsController < ApplicationController
  before_action :require_authentication
  before_action :require_password_change

  def update
    checklist_item = ChecklistItem.joins(:checklist).merge(Checklist.active).find(params[:checklist_item_id])
    completion = current_user.checklist_item_completions.find_or_initialize_by(checklist_item: checklist_item)
    completion.actual_completed_at = completed_param? ? Time.current : nil

    if completion.save
      respond_to do |format|
        format.html { redirect_to checklist_path(checklist_item.checklist), notice: "Checklist item updated." }
        format.json { render json: completion_payload(checklist_item, completion) }
      end
    else
      respond_to do |format|
        format.html { redirect_to checklist_path(checklist_item.checklist), alert: completion.errors.full_messages.to_sentence }
        format.json { render json: { error: completion.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      end
    end
  end

  private

  def completion_payload(checklist_item, completion)
    {
      completed: completion.completed?,
      actual_html: helpers.browser_local_clock_time(completion.actual_completed_at).to_s,
      deviation_text: helpers.formatted_deviation(completion),
      button_label: completion.completed? ? "Mark Incomplete" : "Complete Item",
      button_class: completion.completed? ? "secondary-button" : "primary-button",
      next_completed_value: (!completion.completed?).to_s
    }
  end

  def completed_param?
    ActiveModel::Type::Boolean.new.cast(params[:completed])
  end
end
