class User < ApplicationRecord
  USER_ID_FORMAT = /\A[a-z0-9_.-]+\z/
  EMAIL_FORMAT = /\A(?=.{1,254}\z)[^@\s]+@[^@\s]+\.[^@\s]+\z/
  VERIFICATION_CODE_LENGTH = 6
  VERIFICATION_CODE_TTL = 15.minutes
  VERIFICATION_RESEND_INTERVAL = 1.minute
  MAX_VERIFICATION_ATTEMPTS = 5
  WEAK_PASSWORDS = %w[
    password12345
    password123456
    changeme12345
    qwerty123456
    letmein123456
  ].freeze
  attr_accessor :skip_initial_email_verification_default

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
  before_validation :default_email_verified_at, on: :create
  validate :password_not_obviously_weak, if: :password_present?

  def locked?
    locked_at.present?
  end

  def enabled_for_authentication?
    enabled? && email_verified?
  end

  def email_verified?
    email_verified_at.present?
  end

  def verification_pending?
    !email_verified?
  end

  def verification_code_expired?
    verification_code_sent_at.blank? || verification_code_sent_at < VERIFICATION_CODE_TTL.ago
  end

  def verification_resend_allowed?
    verification_code_sent_at.blank? || verification_code_sent_at <= VERIFICATION_RESEND_INTERVAL.ago
  end

  def prepare_email_verification!(code: self.class.generate_verification_code)
    update!(
      email_verified_at: nil,
      verification_code_digest: digest_verification_code(code),
      verification_code_sent_at: Time.current,
      verification_attempts: 0
    )
    code
  end

  def verify_email_code!(code)
    increment!(:verification_attempts)
    return false if verification_attempts > MAX_VERIFICATION_ATTEMPTS
    return false if verification_code_expired?
    return false if verification_code_digest.blank?
    return false unless BCrypt::Password.new(verification_code_digest).is_password?(code.to_s)

    update!(
      email_verified_at: Time.current,
      verification_code_digest: nil,
      verification_code_sent_at: nil,
      verification_attempts: 0
    )
    true
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def self.generate_verification_code
    format("%0#{VERIFICATION_CODE_LENGTH}d", SecureRandom.random_number(10**VERIFICATION_CODE_LENGTH))
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

  def digest_verification_code(code)
    BCrypt::Password.create(code.to_s)
  end

  def normalize_identity_fields
    self.user_id = user_id.to_s.strip.downcase.presence
    self.email = email.to_s.strip.downcase.presence
  end

  def default_email_verified_at
    return if skip_initial_email_verification_default

    self.email_verified_at ||= Time.current
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
