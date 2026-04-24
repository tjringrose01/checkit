class Checklist < ApplicationRecord
  has_many :checklist_items, -> { order(:sort_order, :id) }, dependent: :destroy

  enum :status, { inactive: "inactive", active: "active" }, default: :active

  validates :title, presence: true, length: { maximum: 150 }
  validates :notes, length: { maximum: 5_000 }, allow_blank: true
  validates :status, presence: true
end
