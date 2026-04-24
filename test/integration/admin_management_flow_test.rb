require "test_helper"
require "tempfile"

class AdminManagementFlowTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      user_id: "admin01",
      email: "admin01@example.com",
      role: "admin",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )
    @user = User.create!(
      user_id: "member10",
      email: "member10@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )
    @checklist = Checklist.create!(title: "Closing Tasks", notes: "End of day", status: "active")
  end

  test "non-admin users cannot access the admin workspace" do
    sign_in_as(@user)

    get admin_root_path

    assert_redirected_to root_path
  end

  test "admin can create a checklist and checklist item" do
    sign_in_as(@admin)

    post admin_checklists_path, params: {
      checklist: {
        title: "Opening Tasks",
        notes: "Daily start",
        status: "active"
      }
    }
    assert_redirected_to admin_checklists_path

    created_checklist = Checklist.find_by!(title: "Opening Tasks")

    post admin_checklist_checklist_items_path(created_checklist), params: {
      checklist_item: {
        item_text: "Power on terminals",
        sort_order: 1,
        desired_completion_at: "2026-04-23T08:30"
      }
    }

    assert_redirected_to admin_checklists_path
    assert_equal 1, created_checklist.checklist_items.where(item_text: "Power on terminals").count
  end

  test "admin can import checklist items from csv" do
    sign_in_as(@admin)

    post admin_checklist_checklist_item_import_path(@checklist), params: {
      file: csv_upload("item_text,sort_order,desired_completion_at\nLock side door,2,2026-04-23 17:15\n")
    }

    assert_redirected_to admin_checklists_path
    imported_item = @checklist.checklist_items.find_by!(item_text: "Lock side door")
    assert_equal 2, imported_item.sort_order
  end

  test "csv import rejects malformed files with actionable errors" do
    sign_in_as(@admin)

    assert_no_difference -> { @checklist.checklist_items.count } do
      post admin_checklist_checklist_item_import_path(@checklist), params: {
        file: csv_upload("item_text,desired_completion_at\nBroken row,2026-04-23 17:15\n")
      }
    end

    assert_redirected_to admin_checklists_path
    follow_redirect!
    assert_match "CSV is missing required headers: sort_order", response.body
  end

  test "admin can unlock a locked user" do
    @user.update!(failed_login_attempts: 6, locked_at: Time.current)
    sign_in_as(@admin)

    patch unlock_admin_user_path(@user)

    assert_redirected_to admin_root_path
    assert_equal 0, @user.reload.failed_login_attempts
    assert_nil @user.locked_at
    assert_equal [ @user.email ], ActionMailer::Base.deliveries.last.to
  end

  private

  def sign_in_as(user)
    post session_path, params: { user_id: user.user_id, password: "StrongerPass123" }
    expected_path = user.must_change_password? ? edit_password_change_path : root_path
    assert_redirected_to expected_path
  end

  def csv_upload(contents)
    file = Tempfile.new([ "checklist-items", ".csv" ])
    file.write(contents)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "text/csv")
  end
end
