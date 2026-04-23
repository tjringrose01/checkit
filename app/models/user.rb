class User < ApplicationRecord
  has_many :checklist_item_completions, dependent: :destroy
  has_many :completed_checklist_items, through: :checklist_item_completions, source: :checklist_item

  enum :role, { admin: "admin", user: "user" }, default: :user
end
