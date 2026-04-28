require "test_helper"
require "ostruct"

class ChecklistItemTest < ActiveSupport::TestCase
  setup do
    @checklist = Checklist.create!(title: "Opening tasks", notes: "Daily startup", start_at: Time.utc(2000, 1, 1, 8, 0, 0))
  end

  test "requires item text" do
    checklist_item = @checklist.checklist_items.build(sort_order: 1, desired_completion_offset_minutes: 15)

    assert_not checklist_item.valid?
    assert_includes checklist_item.errors[:item_text], "can't be blank"
  end

  test "requires a non-negative sort order" do
    checklist_item = @checklist.checklist_items.build(
      item_text: "Unlock doors",
      sort_order: -1,
      desired_completion_offset_minutes: 15
    )

    assert_not checklist_item.valid?
    assert_includes checklist_item.errors[:sort_order], "must be greater than or equal to 0"
  end

  test "requires a non-negative desired completion offset" do
    checklist_item = @checklist.checklist_items.build(
      item_text: "Unlock doors",
      sort_order: 1,
      desired_completion_offset_minutes: -5
    )

    assert_not checklist_item.valid?
    assert_includes checklist_item.errors[:desired_completion_offset_minutes], "must be greater than or equal to 0"
  end

  test "computes desired completion time when checklist start is string-backed" do
    checklist_item = ChecklistItem.new(
      item_text: "Unlock doors",
      sort_order: 1,
      desired_completion_offset_minutes: 15
    )

    checklist_double = Object.new
    checklist_double.define_singleton_method(:start_time_on) do |_reference_time|
      Time.zone.parse("2026-04-23 08:00:00 UTC")
    end
    checklist_item.define_singleton_method(:checklist) { checklist_double }

    assert_equal Time.zone.parse("2026-04-23 08:15:00 UTC"), checklist_item.desired_completion_at
  end

  test "calculates desired completion time from the reference day and start time" do
    checklist_item = @checklist.checklist_items.create!(
      item_text: "Unlock doors",
      sort_order: 1,
      desired_completion_offset_minutes: 90
    )

    assert_equal Time.utc(2026, 4, 23, 9, 30, 0), checklist_item.desired_completion_at(reference_time: Time.utc(2026, 4, 23, 12, 0, 0))
  end
end
