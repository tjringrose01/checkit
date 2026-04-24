require "test_helper"

class ChecklistItemTest < ActiveSupport::TestCase
  setup do
    @checklist = Checklist.create!(title: "Opening tasks", notes: "Daily startup")
  end

  test "requires item text" do
    checklist_item = @checklist.checklist_items.build(sort_order: 1)

    assert_not checklist_item.valid?
    assert_includes checklist_item.errors[:item_text], "can't be blank"
  end

  test "requires a non-negative sort order" do
    checklist_item = @checklist.checklist_items.build(item_text: "Unlock doors", sort_order: -1)

    assert_not checklist_item.valid?
    assert_includes checklist_item.errors[:sort_order], "must be greater than or equal to 0"
  end
end
