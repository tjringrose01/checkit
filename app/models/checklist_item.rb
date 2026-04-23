class ChecklistItem < ApplicationRecord
  belongs_to :checklist

  has_many :checklist_item_completions, dependent: :destroy
  has_many :users, through: :checklist_item_completions
end
