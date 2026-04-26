require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes identity fields before validation" do
    user = User.create!(
      user_id: "  Member.01  ",
      email: "  MEMBER01@Example.COM ",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )

    assert_equal "member.01", user.user_id
    assert_equal "member01@example.com", user.email
  end

  test "rejects invalid user_id format" do
    user = User.new(
      user_id: "bad id",
      email: "member03@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )

    assert_not user.valid?
    assert_includes user.errors[:user_id], "is invalid"
  end

  test "rejects invalid email format" do
    user = User.new(
      user_id: "member03",
      email: "invalid-email",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )

    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "rejects obviously weak passwords" do
    user = User.new(
      user_id: "member04",
      email: "member04@example.com",
      password: "password12345",
      password_confirmation: "password12345"
    )

    assert_not user.valid?
    assert_includes user.errors[:password], "is too weak"
  end

  test "locks after more than five failed attempts" do
    user = User.create!(
      user_id: "member01",
      email: "member01@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )

    6.times { user.record_failed_login! }
    user.reload

    assert user.locked?
    assert_equal 6, user.failed_login_attempts
  end

  test "successful login resets attempts and records last login" do
    user = User.create!(
      user_id: "member02",
      email: "member02@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123",
      failed_login_attempts: 4
    )

    user.record_successful_login!
    user.reload

    assert_equal 0, user.failed_login_attempts
    assert_not_nil user.last_login_at
  end

  test "unlock_access clears lock state" do
    user = User.create!(
      user_id: "member05",
      email: "member05@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123",
      failed_login_attempts: 6,
      locked_at: Time.current
    )

    user.unlock_access!
    user.reload

    assert_equal 0, user.failed_login_attempts
    assert_nil user.locked_at
  end

  test "enabled defaults to true" do
    user = User.create!(
      user_id: "member06",
      email: "member06@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )

    assert_equal true, user.enabled
    assert user.enabled_for_authentication?
  end

  test "unverified users are not enabled for authentication" do
    user = User.new(
      user_id: "member07",
      email: "member07@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123",
      email_verified_at: nil
    )
    user.skip_initial_email_verification_default = true
    user.save!

    assert_not user.enabled_for_authentication?
  end

  test "email verification code can activate a pending user" do
    user = User.create!(
      user_id: "member08",
      email: "member08@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123",
      email_verified_at: nil
    )
    code = user.prepare_email_verification!(code: "123456")

    assert_equal "123456", code
    assert user.verify_email_code!("123456")
    assert user.reload.email_verified?
    assert_nil user.verification_code_digest
  end
end
