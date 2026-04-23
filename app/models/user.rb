class User < ApplicationRecord
  has_secure_password

  has_many :checklist_item_completions, dependent: :destroy
  has_many :completed_checklist_items, through: :checklist_item_completions, source: :checklist_item

  enum :role, { admin: "admin", user: "user" }, default: :user

  validates :user_id, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true
  validates :password, length: { minimum: 12 }, allow_nil: true

  before_validation :normalize_identity_fields

  def locked?
    locked_at.present?
  end

  def record_failed_login!
    attempts = failed_login_attempts + 1
    attributes = { failed_login_attempts: attempts, updated_at: Time.current }
    attributes[:locked_at] = Time.current if attempts > 5
    update_columns(attributes)
  end

  def record_successful_login!
    update_columns(
      failed_login_attempts: 0,
      last_login_at: Time.current,
      updated_at: Time.current
    )
  end

  def unlock_access!
    update!(
      failed_login_attempts: 0,
      locked_at: nil
    )
  end

  private

  def normalize_identity_fields
    self.user_id = user_id.to_s.strip.downcase.presence
    self.email = email.to_s.strip.downcase.presence
  end
end
