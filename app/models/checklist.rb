class Checklist < ApplicationRecord
  has_many :checklist_items, -> { order(:sort_order, :id) }, dependent: :destroy

  enum :status, { inactive: "inactive", active: "active" }, default: :active
end
