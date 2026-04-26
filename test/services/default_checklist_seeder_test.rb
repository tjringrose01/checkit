require "test_helper"

class DefaultChecklistSeederTest < ActiveSupport::TestCase
  test "seeds the SPL-Shakedown checklist for development builds on dev" do
    assert_difference -> { Checklist.count }, 1 do
      DefaultChecklistSeeder.call(rails_env: "development", build_environment: "dev")
    end

    checklist = Checklist.find_by!(title: "SPL-Shakedown Checklist")

    assert_equal "Checklist for running a shakedown.", checklist.notes
    assert_equal "active", checklist.status
    assert_equal "07:00 PM", checklist.start_at.in_time_zone("UTC").strftime("%I:%M %p")
    assert_equal 9, checklist.checklist_items.count
    assert_equal 90, checklist.checklist_items.order(:sort_order, :id).last.desired_completion_offset_minutes
    assert_match "<ol>", checklist.checklist_items.find_by(sort_order: 6).item_text
  end

  test "does not seed the checklist outside dev builds" do
    assert_no_difference -> { Checklist.count } do
      DefaultChecklistSeeder.call(rails_env: "development", build_environment: "prod")
    end

    assert_nil Checklist.find_by(title: "SPL-Shakedown Checklist")
  end

  test "does not seed the checklist in test env even when the build tag is dev" do
    assert_no_difference -> { Checklist.count } do
      DefaultChecklistSeeder.call(rails_env: "test", build_environment: "dev")
    end

    assert_nil Checklist.find_by(title: "SPL-Shakedown Checklist")
  end

  test "is idempotent for repeated development seeding" do
    DefaultChecklistSeeder.call(rails_env: "development", build_environment: "dev")

    assert_no_difference -> { Checklist.count } do
      DefaultChecklistSeeder.call(rails_env: "development", build_environment: "dev")
    end

    checklist = Checklist.find_by!(title: "SPL-Shakedown Checklist")
    assert_equal 9, checklist.checklist_items.count
  end
end
