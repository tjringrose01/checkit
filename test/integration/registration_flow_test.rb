require "test_helper"

class RegistrationFlowTest < ActionDispatch::IntegrationTest
  test "login page links to registration" do
    get new_session_path

    assert_response :success
    assert_match "Register", response.body
  end

  test "user can register, receive a verification email, verify, and be signed in" do
    assert_difference -> { User.count }, 1 do
      post registration_path, params: {
        user: {
          user_id: "newmember",
          email: "newmember@example.com",
          password: "StrongerPass123",
          password_confirmation: "StrongerPass123"
        }
      }
    end

    user = User.find_by!(user_id: "newmember")
    assert_redirected_to email_verification_path
    assert_not user.email_verified?
    assert_equal [ user.email ], ActionMailer::Base.deliveries.last.to

    code = ActionMailer::Base.deliveries.last.body.to_s[/\b\d{6}\b/]
    post email_verification_path, params: { email_verification: { code: code } }

    assert_redirected_to root_path
    assert user.reload.email_verified?

    follow_redirect!
    assert_response :success
    assert_match "Signed in as", response.body
  end

  test "unverified user with correct password is redirected to verification" do
    user = User.new(
      user_id: "pendingmember",
      email: "pendingmember@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )
    user.skip_initial_email_verification_default = true
    user.save!
    user.prepare_email_verification!(code: "123456")

    post session_path, params: { user_id: user.user_id, password: "StrongerPass123" }

    assert_redirected_to email_verification_path
  end

  test "resend verification sends a new email when allowed" do
    user = User.new(
      user_id: "resendmember",
      email: "resendmember@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )
    user.skip_initial_email_verification_default = true
    user.save!
    user.prepare_email_verification!(code: "123456")
    user.update_column(:verification_code_sent_at, 2.minutes.ago)
    post session_path, params: { user_id: user.user_id, password: "StrongerPass123" }

    assert_difference -> { ActionMailer::Base.deliveries.count }, 1 do
      patch resend_email_verification_path
    end

    assert_redirected_to email_verification_path
  end

  test "resend verification is rate limited" do
    user = User.new(
      user_id: "waitmember",
      email: "waitmember@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )
    user.skip_initial_email_verification_default = true
    user.save!
    user.prepare_email_verification!(code: "123456")
    post session_path, params: { user_id: user.user_id, password: "StrongerPass123" }

    assert_no_difference -> { ActionMailer::Base.deliveries.count } do
      patch resend_email_verification_path
    end

    assert_redirected_to email_verification_path
  end
end
