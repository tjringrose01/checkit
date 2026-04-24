class User < ApplicationRecord
  USER_ID_FORMAT = /\A[a-z0-9_.-]+\z/
  EMAIL_FORMAT = /\A(?=.{1,254}\z)[^@\s]+@[^@\s]+\.[^@\s]+\z/
  WEAK_PASSWORDS = %w[
    password12345
    password123456
    changeme12345
    qwerty123456
    letmein123456
  ].freeze

  has_secure_password

  has_many :checklist_item_completions, dependent: :destroy
  has_many :completed_checklist_items, through: :checklist_item_completions, source: :checklist_item

  enum :role, { admin: "admin", user: "user" }, default: :user

  validates :user_id,
            presence: true,
            uniqueness: true,
            length: { minimum: 4, maximum: 50 },
            format: { with: USER_ID_FORMAT }
  validates :email,
            presence: true,
            uniqueness: true,
            length: { maximum: 254 },
            format: { with: EMAIL_FORMAT }
  validates :enabled, inclusion: { in: [ true, false ] }
  validates :role, presence: true
  validates :password, length: { minimum: 12 }, allow_nil: true

  before_validation :normalize_identity_fields
  validate :password_not_obviously_weak, if: :password_present?

  def locked?
    locked_at.present?
  end

  def enabled_for_authentication?
    enabled?
  end

  def record_failed_login!
    return if locked?

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

  def password_present?
    password.present?
  end

  def password_not_obviously_weak
    normalized_password = password.to_s.downcase
    return unless WEAK_PASSWORDS.include?(normalized_password)

    errors.add(:password, "is too weak")
  end
end
