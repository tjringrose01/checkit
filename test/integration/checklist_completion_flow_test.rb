require "test_helper"

class ChecklistCompletionFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      user_id: "operator02",
      email: "operator02@example.com",
      must_change_password: false,
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )
    @active_checklist = Checklist.create!(
      title: "Opening checks",
      notes: "Before service starts",
      status: "active",
      start_at: Time.utc(2000, 1, 1, 8, 30, 0)
    )
    @inactive_checklist = Checklist.create!(
      title: "Archived",
      notes: "Not visible",
      status: "inactive",
      start_at: Time.utc(2000, 1, 1, 12, 0, 0)
    )
    @active_item = @active_checklist.checklist_items.create!(
      item_text: "Unlock front door",
      sort_order: 1,
      desired_completion_offset_minutes: 30
    )
    @inactive_item = @inactive_checklist.checklist_items.create!(
      item_text: "Legacy item",
      sort_order: 1,
      desired_completion_offset_minutes: 0
    )
  end

  test "dashboard requires authentication" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "authenticated users see active checklists and not inactive ones" do
    sign_in_as(@user)

    get root_path

    assert_response :success
    assert_match "Opening checks", response.body
    assert_no_match "Archived", response.body
    assert_match "Open Checklist", response.body
    assert_no_match "Unlock front door", response.body
  end

  test "selected checklist shows only that checklist's items" do
    second_checklist = Checklist.create!(
      title: "Midday Tasks",
      notes: "Lunch prep",
      status: "active",
      start_at: Time.utc(2000, 1, 1, 11, 30, 0)
    )
    second_checklist.checklist_items.create!(item_text: "Prep salad bar", sort_order: 1, desired_completion_offset_minutes: 15)
    sign_in_as(@user)

    get checklist_path(@active_checklist)

    assert_response :success
    assert_match "Unlock front door", response.body
    assert_no_match "Prep salad bar", response.body
  end

  test "checklist item html is rendered for authenticated users" do
    @active_item.update!(item_text: "<strong>Unlock</strong> front door<br><em>before 8am</em>")
    sign_in_as(@user)

    get checklist_path(@active_checklist)

    assert_response :success
    assert_match "<strong>Unlock</strong>", response.body
    assert_match "<em>before 8am</em>", response.body
    assert_no_match "&lt;strong&gt;Unlock&lt;/strong&gt;", response.body
    assert_match "30 minutes from start", response.body
    assert_match 'data-local-format="time"', response.body
  end

  test "user can complete and uncomplete an item" do
    sign_in_as(@user)

    patch checklist_item_completion_path(@active_item), params: { completed: true }
    assert_redirected_to checklist_path(@active_checklist)

    completion = @user.checklist_item_completions.find_by!(checklist_item: @active_item)
    assert completion.completed?
    assert_not_nil completion.actual_completed_at

    patch checklist_item_completion_path(@active_item), params: { completed: false }
    assert_redirected_to checklist_path(@active_checklist)

    completion.reload
    assert_not completion.completed?
    assert_nil completion.actual_completed_at
  end

  test "inactive checklist items cannot be updated through the completion endpoint" do
    sign_in_as(@user)

    assert_raises ActiveRecord::RecordNotFound do
      patch checklist_item_completion_path(@inactive_item), params: { completed: true }
    end
  end

  private

  def sign_in_as(user)
    post session_path, params: { user_id: user.user_id, password: "StrongerPass123" }
    assert_redirected_to root_path
  end
end
