class ChecklistItemCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :checklist_item

  before_validation :sync_completion_state

  private

  def sync_completion_state
    return unless actual_completed_at_changed?

    self.completed = actual_completed_at.present?
  end
end
