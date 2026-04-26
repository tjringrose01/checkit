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
    @checklist = Checklist.create!(
      title: "Closing Tasks",
      notes: "End of day",
      status: "active",
      start_at: Time.utc(2000, 1, 1, 17, 0, 0)
    )
  end

  test "non-admin users cannot access the admin workspace" do
    sign_in_as(@user)

    get admin_root_path

    assert_redirected_to root_path
  end

  test "non-admin users cannot access admin user management" do
    sign_in_as(@user)

    get admin_users_path

    assert_redirected_to root_path
  end

  test "admin can create a checklist and checklist item" do
    sign_in_as(@admin)

    post admin_checklists_path, params: {
      checklist: {
        title: "Opening Tasks",
        notes: "Daily start",
        status: "active",
        start_at: "08:00 AM"
      }
    }
    created_checklist = Checklist.find_by!(title: "Opening Tasks")
    assert_redirected_to admin_checklist_path(created_checklist)

    post admin_checklist_checklist_items_path(created_checklist), params: {
      checklist_item: {
        item_text: "Power on terminals",
        sort_order: 1,
        desired_completion_offset_minutes: 30
      }
    }

    assert_redirected_to admin_checklist_path(created_checklist)
    assert_equal 1, created_checklist.checklist_items.where(item_text: "Power on terminals").count
  end

  test "admin can update checklist details from the checklist workspace" do
    sign_in_as(@admin)

    patch admin_checklist_path(@checklist), params: {
      checklist: {
        title: "Revised Closing Tasks",
        notes: "Updated notes",
        status: "inactive",
        start_at: "06:30 PM"
      }
    }

    assert_redirected_to admin_checklist_path(@checklist)
    @checklist.reload
    assert_equal "Revised Closing Tasks", @checklist.title
    assert_equal "Updated notes", @checklist.notes
    assert_equal "inactive", @checklist.status
    assert_equal Time.utc(2000, 1, 1, 18, 30, 0), @checklist.start_at.utc
  end

  test "admin can update checklist start time to 7:00 PM" do
    sign_in_as(@admin)

    patch admin_checklist_path(@checklist), params: {
      checklist: {
        title: @checklist.title,
        notes: @checklist.notes,
        status: @checklist.status,
        start_at: "07:00 PM"
      }
    }

    assert_redirected_to admin_checklist_path(@checklist)
    @checklist.reload
    assert_equal Time.utc(2000, 1, 1, 19, 0, 0), @checklist.start_at.utc

    get admin_checklist_path(@checklist)
    assert_response :success
    assert_match 'value="07:00 PM"', response.body
  end

  test "admin landing page lists checklists before showing items" do
    @checklist.checklist_items.create!(item_text: "Close register", sort_order: 1, desired_completion_offset_minutes: 15)
    sign_in_as(@admin)

    get admin_root_path

    assert_response :success
    assert_match "Closing Tasks", response.body
    assert_match "Open Checklist", response.body
    assert_no_match "Close register", response.body
  end

  test "admin checklist workspace renders AM/PM time input value for checklist start" do
    sign_in_as(@admin)

    get admin_checklist_path(@checklist)

    assert_response :success
    assert_match 'name="checklist[start_at]"', response.body
    assert_match 'value="05:00 PM"', response.body
    assert_match "Start:</strong> 05:00 PM", response.body
  end

  test "admin checklist item html is rendered in the management view" do
    @checklist.checklist_items.create!(
      item_text: "<p><strong>Close</strong> register</p>",
      sort_order: 1,
      desired_completion_offset_minutes: 20
    )
    sign_in_as(@admin)

    get admin_checklist_path(@checklist)

    assert_response :success
    assert_match "<strong>Close</strong>", response.body
    assert_no_match "&lt;strong&gt;Close&lt;/strong&gt;", response.body
    assert_match "Sort order: 1", response.body
    assert_match "Target time: 05:20 PM", response.body
  end

  test "admin can import checklist items from csv" do
    sign_in_as(@admin)

    post admin_checklist_checklist_item_import_path(@checklist), params: {
      file: csv_upload("item_text,sort_order,desired_completion_offset_minutes\nLock side door,2,15\n")
    }

    assert_redirected_to admin_checklist_path(@checklist)
    imported_item = @checklist.checklist_items.find_by!(item_text: "Lock side door")
    assert_equal 2, imported_item.sort_order
  end

  test "admin can update an existing checklist item through csv using checklist_item_id" do
    sign_in_as(@admin)
    checklist_item = @checklist.checklist_items.create!(
      item_text: "Existing row",
      sort_order: 5,
      desired_completion_offset_minutes: 15
    )

    post admin_checklist_checklist_item_import_path(@checklist), params: {
      file: csv_upload(
        "checklist_item_id,item_text,sort_order,desired_completion_offset_minutes\n" \
        "#{checklist_item.id},Updated row,3,60\n"
      )
    }

    assert_redirected_to admin_checklist_path(@checklist)
    checklist_item.reload
    assert_equal "Updated row", checklist_item.item_text
    assert_equal 3, checklist_item.sort_order
  end

  test "csv import rejects malformed files with actionable errors" do
    sign_in_as(@admin)

    assert_no_difference -> { @checklist.checklist_items.count } do
      post admin_checklist_checklist_item_import_path(@checklist), params: {
        file: csv_upload("item_text,desired_completion_offset_minutes\nBroken row,15\n")
      }
    end

    assert_redirected_to admin_checklist_path(@checklist)
    follow_redirect!
    assert_match "CSV is missing required headers: sort_order", response.body
  end

  test "admin can unlock a locked user" do
    @user.update!(failed_login_attempts: 6, locked_at: Time.current)
    sign_in_as(@admin)

    patch unlock_admin_user_path(@user)

    assert_redirected_to admin_user_path(@user)
    assert_equal 0, @user.reload.failed_login_attempts
    assert_nil @user.locked_at
    assert_equal [ @user.email ], ActionMailer::Base.deliveries.last.to
  end

  test "admin can view the user management catalog" do
    sign_in_as(@admin)

    get admin_users_path

    assert_response :success
    assert_match "User Administration", response.body
    assert_match @user.user_id, response.body
    assert_match "Manage User", response.body
  end

  test "admin can reset a user password and force a password change" do
    sign_in_as(@admin)

    patch reset_password_admin_user_path(@user), params: {
      user: {
        password: "ResetPass1234",
        password_confirmation: "ResetPass1234"
      }
    }

    assert_redirected_to admin_user_path(@user)
    @user.reload
    assert @user.authenticate("ResetPass1234")
    assert @user.must_change_password?
    assert_equal 0, @user.failed_login_attempts
    assert_nil @user.locked_at
  end

  test "admin can disable and enable a user" do
    sign_in_as(@admin)

    patch disable_admin_user_path(@user)
    assert_redirected_to admin_user_path(@user)
    assert_not @user.reload.enabled?

    patch enable_admin_user_path(@user)
    assert_redirected_to admin_user_path(@user)
    assert @user.reload.enabled?
  end

  test "admin cannot disable their own account" do
    sign_in_as(@admin)

    patch disable_admin_user_path(@admin)

    assert_redirected_to admin_user_path(@admin)
    assert @admin.reload.enabled?
  end

  test "admin can delete another user" do
    sign_in_as(@admin)

    assert_difference -> { User.count }, -1 do
      delete admin_user_path(@user)
    end

    assert_redirected_to admin_users_path
    assert_nil User.find_by(id: @user.id)
  end

  test "admin cannot delete their own account" do
    sign_in_as(@admin)

    assert_no_difference -> { User.count } do
      delete admin_user_path(@admin)
    end

    assert_redirected_to admin_user_path(@admin)
    assert_not_nil User.find_by(id: @admin.id)
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
