class ChecklistItem < ApplicationRecord
  belongs_to :checklist

  has_many :checklist_item_completions, dependent: :destroy
  has_many :users, through: :checklist_item_completions

  validates :item_text, presence: true, length: { maximum: 1_000 }
  validates :sort_order,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def completion_for(user)
    checklist_item_completions.find_by(user: user)
  end
end
