require "test_helper"

class ChecklistTest < ActiveSupport::TestCase
  test "requires a title" do
    checklist = Checklist.new(status: "active", start_at: Time.utc(2000, 1, 1, 19, 0, 0))

    assert_not checklist.valid?
    assert_includes checklist.errors[:title], "can't be blank"
  end

  test "requires a checklist start time" do
    checklist = Checklist.new(title: "Evening Checklist", status: "active")

    assert_not checklist.valid?
    assert_includes checklist.errors[:start_at], "can't be blank"
  end

  test "normalizes start time to a canonical stored date" do
    checklist = Checklist.create!(
      title: "Evening Checklist",
      status: "active",
      start_at: Time.utc(2026, 5, 1, 19, 0, 0)
    )

    assert_equal Time.utc(2000, 1, 1, 19, 0, 0), checklist.reload.start_at.utc
  end
end
