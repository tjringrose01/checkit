require "test_helper"

class PasswordResetFlowTest < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.deliveries.clear
    @user = User.create!(
      user_id: "resetmember",
      email: "resetmember@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )
    @admin = User.create!(
      user_id: "adminreset",
      email: "adminreset@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123",
      role: "admin"
    )
  end

  test "user can request a password reset, verify OTP, and set a new password" do
    post password_reset_request_path, params: {
      password_reset_request: {
        user_id: @user.user_id,
        email: @user.email
      }
    }

    assert_redirected_to password_reset_verification_path
    assert_equal [ @user.email ], ActionMailer::Base.deliveries.last.to

    code = ActionMailer::Base.deliveries.last.body.to_s[/\b\d{6}\b/]
    post password_reset_verification_path, params: {
      password_reset_verification: {
        code: code
      }
    }

    assert_redirected_to edit_password_reset_path

    patch password_reset_path, params: {
      user: {
        password: "ReplacementPass123",
        password_confirmation: "ReplacementPass123"
      }
    }

    assert_redirected_to new_session_path
    assert @user.reload.authenticate("ReplacementPass123")
    assert_nil @user.password_reset_code_digest
  end

  test "forgot password page uses username label" do
    get new_password_reset_request_path

    assert_response :success
    assert_match ">Username<", response.body
    refute_match(/class="logo" href=/, response.body)
    refute_match(/Dashboard/, response.body)
  end

  test "admin users cannot use self-service password reset" do
    post password_reset_request_path, params: {
      password_reset_request: {
        user_id: @admin.user_id,
        email: @admin.email
      }
    }

    assert_redirected_to new_password_reset_request_path
    assert_equal 0, ActionMailer::Base.deliveries.count
  end

  test "password reset verification can be resent when allowed" do
    post password_reset_request_path, params: {
      password_reset_request: {
        user_id: @user.user_id,
        email: @user.email
      }
    }
    @user.reload.update_column(:password_reset_code_sent_at, 2.minutes.ago)

    assert_difference -> { ActionMailer::Base.deliveries.count }, 1 do
      patch resend_password_reset_verification_path
    end

    assert_redirected_to password_reset_verification_path
  end
end
