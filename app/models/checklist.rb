class Checklist < ApplicationRecord
  has_many :checklist_items, -> { order(:sort_order, :id) }, dependent: :destroy

  enum :status, { inactive: "inactive", active: "active" }, default: :active

  before_validation :normalize_start_time

  validates :title, presence: true, length: { maximum: 150 }
  validates :notes, length: { maximum: 5_000 }, allow_blank: true
  validates :start_at, presence: true
  validates :status, presence: true

  def start_time_on(reference_time)
    return if start_at.blank? || reference_time.blank?

    reference = reference_time.in_time_zone("UTC")
    stored = start_at.in_time_zone("UTC")
    Time.utc(reference.year, reference.month, reference.day, stored.hour, stored.min, stored.sec)
  end

  private

  def normalize_start_time
    return if start_at.blank?

    parsed_time =
      case start_at
      when String
        Time.zone.parse(start_at)
      else
        start_at.in_time_zone
      end

    return if parsed_time.blank?

    self.start_at = Time.utc(2000, 1, 1, parsed_time.hour, parsed_time.min, parsed_time.sec)
  end
end
