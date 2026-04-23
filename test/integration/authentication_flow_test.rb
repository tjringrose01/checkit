require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      user_id: "operator01",
      email: "operator01@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )
  end

  test "user signs in with user_id" do
    post session_path, params: { user_id: @user.user_id, password: "StrongerPass123" }

    assert_redirected_to root_path
    assert_not_nil @user.reload.last_login_at
  end

  test "email cannot be used in place of user_id" do
    post session_path, params: { user_id: @user.email, password: "StrongerPass123" }

    assert_redirected_to new_session_path
  end

  test "forced password change redirects before normal app access" do
    @user.update!(must_change_password: true)

    post session_path, params: { user_id: @user.user_id, password: "StrongerPass123" }

    assert_redirected_to edit_password_change_path
  end

  test "account locks after repeated failed sign in attempts" do
    6.times do
      post session_path, params: { user_id: @user.user_id, password: "wrong-password" }
      assert_redirected_to new_session_path
    end

    assert @user.reload.locked?
    assert_equal 6, @user.failed_login_attempts
  end

  test "locked accounts cannot sign in even with the correct password" do
    @user.update!(failed_login_attempts: 6, locked_at: Time.current)

    post session_path, params: { user_id: @user.user_id, password: "StrongerPass123" }

    assert_redirected_to new_session_path
    assert_equal 6, @user.reload.failed_login_attempts
  end

  test "disabled accounts cannot sign in" do
    @user.update!(enabled: false)

    post session_path, params: { user_id: @user.user_id, password: "StrongerPass123" }

    assert_redirected_to new_session_path
    assert_equal 0, @user.reload.failed_login_attempts
  end

  test "forced password change clears must_change_password after successful update" do
    @user.update!(must_change_password: true)

    post session_path, params: { user_id: @user.user_id, password: "StrongerPass123" }
    follow_redirect!

    patch password_change_path, params: {
      password_change: {
        current_password: "StrongerPass123",
        password: "ReplacementPass123",
        password_confirmation: "ReplacementPass123"
      }
    }

    assert_redirected_to root_path
    assert_not @user.reload.must_change_password?
    assert @user.authenticate("ReplacementPass123")
  end
end
