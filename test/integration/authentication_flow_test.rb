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

  test "sign in page shows build metadata footer" do
    previous_environment = ENV["APP_BUILD_ENVIRONMENT"]
    previous_number = ENV["APP_BUILD_NUMBER"]
    previous_version = ENV["APP_VERSION"]
    previous_git_sha = ENV["APP_GIT_SHA"]

    ENV["APP_BUILD_ENVIRONMENT"] = "dev"
    ENV["APP_BUILD_NUMBER"] = "99"
    ENV["APP_VERSION"] = "v1.2.3"
    ENV["APP_GIT_SHA"] = "abcdef1234567890"

    get new_session_path

    assert_response :success
    assert_match(/Checkit \| Copyright \d{4} \| Dev Environment \| Build dev-99 \| Built/, response.body)
    assert_match "Dev Environment", response.body
  ensure
    ENV["APP_BUILD_ENVIRONMENT"] = previous_environment
    ENV["APP_BUILD_NUMBER"] = previous_number
    ENV["APP_VERSION"] = previous_version
    ENV["APP_GIT_SHA"] = previous_git_sha
  end

  test "sign in page renders an explicitly styled submit button" do
    get new_session_path

    assert_response :success
    assert_match(/value="Sign in"/, response.body)
    assert_match(/class="primary-button"/, response.body)
  end

  test "sign in page uses username label" do
    get new_session_path

    assert_response :success
    assert_match ">Username<", response.body
  end

  test "sign in page hides authenticated navigation chrome" do
    get new_session_path

    assert_response :success
    refute_match(/Open user menu/, response.body)
    refute_match(/Dashboard/, response.body)
    refute_match(/class="nav-link" href="\/session\/new"/, response.body)
    refute_match(/class="logo" href=/, response.body)
  end

  test "redirect to sign in from protected page does not show please sign in alert" do
    get root_path

    assert_redirected_to new_session_path
    follow_redirect!

    assert_response :success
    refute_match "Please sign in to continue.", response.body
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

  test "authenticated layout uses home logo link and user menu actions" do
    post session_path, params: { user_id: @user.user_id, password: "StrongerPass123" }
    follow_redirect!

    assert_response :success
    assert_match(/class="logo" href="#{Regexp.escape(root_path)}"/, response.body)
    assert_match(/aria-label="Open user menu"/, response.body)
    assert_match "Sign out", response.body
    refute_match "Signed in as", response.body
  end

  test "flash notices render dismiss controls" do
    post session_path, params: { user_id: @user.user_id, password: "StrongerPass123" }
    follow_redirect!

    assert_response :success
    assert_match(/data-dismiss-flash/, response.body)
    assert_match(/aria-label="Dismiss message"/, response.body)
    assert_match(/Notice: Signed in\./, response.body)
  end
end
