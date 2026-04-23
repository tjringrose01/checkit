require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "locks after more than five failed attempts" do
    user = User.create!(
      user_id: "member01",
      email: "member01@example.com",
      password: "password12345",
      password_confirmation: "password12345"
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
      password: "password12345",
      password_confirmation: "password12345",
      failed_login_attempts: 4
    )

    user.record_successful_login!
    user.reload

    assert_equal 0, user.failed_login_attempts
    assert_not_nil user.last_login_at
  end
end
