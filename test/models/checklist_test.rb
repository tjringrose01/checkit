require "test_helper"

class ChecklistTest < ActiveSupport::TestCase
  test "requires a title" do
    checklist = Checklist.new(status: "active")

    assert_not checklist.valid?
    assert_includes checklist.errors[:title], "can't be blank"
  end
end
