class ChecklistItemCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :checklist_item

  validates :user_id, uniqueness: { scope: :checklist_item_id }
  validates :completed, inclusion: { in: [ true, false ] }
  validate :actual_completion_state_is_consistent

  before_validation :sync_completion_state
  before_validation :calculate_deviation

  def deviation_status
    return "pending" unless completed?
    return "on_time" if completion_deviation_seconds.to_i.zero?
    return "early" if completion_deviation_seconds.to_i.negative?

    "late"
  end

  private

  def sync_completion_state
    return unless will_save_change_to_actual_completed_at?

    self.completed = actual_completed_at.present?
  end

  def calculate_deviation
    if actual_completed_at.blank?
      self.completion_deviation_seconds = nil
      return
    end

    desired_completion_at = checklist_item&.desired_completion_at(reference_time: actual_completed_at)
    self.completion_deviation_seconds =
      if desired_completion_at.present?
        actual_completed_at.to_i - desired_completion_at.to_i
      end
  end

  def actual_completion_state_is_consistent
    return if completed? == actual_completed_at.present?

    errors.add(:actual_completed_at, "must be present when completed and blank when not completed")
  end
end
