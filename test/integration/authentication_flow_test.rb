require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      user_id: "operator01",
      email: "operator01@example.com",
      password: "password12345",
      password_confirmation: "password12345"
    )
  end

  test "user signs in with user_id" do
    post session_path, params: { user_id: @user.user_id, password: "password12345" }

    assert_redirected_to root_path
    assert_not_nil @user.reload.last_login_at
  end

  test "email cannot be used in place of user_id" do
    post session_path, params: { user_id: @user.email, password: "password12345" }

    assert_redirected_to new_session_path
  end

  test "forced password change redirects before normal app access" do
    @user.update!(must_change_password: true)

    post session_path, params: { user_id: @user.user_id, password: "password12345" }

    assert_redirected_to edit_password_change_path
  end
end
