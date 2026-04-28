class ChecklistItem < ApplicationRecord
  belongs_to :checklist

  has_many :checklist_item_completions, dependent: :destroy
  has_many :users, through: :checklist_item_completions

  validates :item_text, presence: true, length: { maximum: 1_000 }
  validates :desired_completion_offset_minutes,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sort_order,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def completion_for(user)
    checklist_item_completions.find_by(user: user)
  end

  def desired_completion_at(reference_time: Time.current)
    start_time = checklist&.start_time_on(reference_time)
    start_time&.+(desired_completion_offset_minutes.to_i.minutes)
  end
end
