require "test_helper"

class ChecklistItemCompletionTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      user_id: "worker01",
      email: "worker01@example.com",
      password: "StrongerPass123",
      password_confirmation: "StrongerPass123"
    )
    @checklist = Checklist.create!(title: "Opening tasks", notes: "Daily startup")
    @checklist_item = @checklist.checklist_items.create!(
      item_text: "Unlock doors",
      sort_order: 1,
      desired_completion_at: Time.utc(2026, 4, 23, 9, 0, 0)
    )
  end

  test "calculates late completion deviation" do
    completion = ChecklistItemCompletion.create!(
      user: @user,
      checklist_item: @checklist_item,
      actual_completed_at: Time.utc(2026, 4, 23, 9, 5, 0)
    )

    assert completion.completed?
    assert_equal 300, completion.completion_deviation_seconds
    assert_equal "late", completion.deviation_status
  end

  test "calculates early completion deviation" do
    completion = ChecklistItemCompletion.create!(
      user: @user,
      checklist_item: @checklist_item,
      actual_completed_at: Time.utc(2026, 4, 23, 8, 55, 0)
    )

    assert_equal(-300, completion.completion_deviation_seconds)
    assert_equal "early", completion.deviation_status
  end

  test "clears completion state when actual completion is removed" do
    completion = ChecklistItemCompletion.create!(
      user: @user,
      checklist_item: @checklist_item,
      actual_completed_at: Time.utc(2026, 4, 23, 9, 0, 0)
    )

    completion.update!(actual_completed_at: nil)

    assert_not completion.completed?
    assert_nil completion.completion_deviation_seconds
    assert_equal "pending", completion.deviation_status
  end

  test "enforces one completion record per user and checklist item" do
    ChecklistItemCompletion.create!(
      user: @user,
      checklist_item: @checklist_item,
      actual_completed_at: Time.utc(2026, 4, 23, 9, 0, 0)
    )

    duplicate = ChecklistItemCompletion.new(
      user: @user,
      checklist_item: @checklist_item,
      actual_completed_at: Time.utc(2026, 4, 23, 9, 1, 0)
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
