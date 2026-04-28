class DefaultChecklistSeeder
  SPL_SHAKEDOWN_CHECKLIST = {
    title: "SPL-Shakedown Checklist",
    notes: "Checklist for running a shakedown.",
    status: "active",
    start_at: "07:00 PM",
    items: [
      { sort_order: 0, desired_completion_offset_minutes: 0, item_text: "Confirm Tent Plan with Patrol Leaders" },
      { sort_order: 0, desired_completion_offset_minutes: 0, item_text: "Confirm patrol equipment plan with patrol leaders." },
      { sort_order: 1, desired_completion_offset_minutes: 10, item_text: "Test Stoves and Fuel Pumps" },
      { sort_order: 1, desired_completion_offset_minutes: 30, item_text: "Setup Tents" },
      { sort_order: 2, desired_completion_offset_minutes: 35, item_text: "Inspect Tents" },
      { sort_order: 3, desired_completion_offset_minutes: 50, item_text: "Patrol equipment staging" },
      { sort_order: 4, desired_completion_offset_minutes: 80, item_text: "Personal equipment check" },
      { sort_order: 5, desired_completion_offset_minutes: 85, item_text: "Line up" },
      {
        sort_order: 6,
        desired_completion_offset_minutes: 90,
        item_text: <<~HTML.strip
          Announcements:
          <ol>
            <li>Who are patrol leaders? </li>
            <li>Do you know what the plan is for the weekend? </li>
            <li>Where are we going? </li>
            <li>Are you prepared for food? </li>
            <li>Who is shopping? </li>
            <li>Are you prepared for tents? </li>
            <li>Are you prepared for equipment?</li>
            <li>Do your patrol members know what personal equipment they are missing? </li>
            <li>Will you ensure that they are prepared when they arrive tomorrow? </li>
            <li>What time to arrive at the church? </li>
          </ol>
        HTML
      }
    ]
  }.freeze

  def self.call(...)
    new.call(...)
  end

  def call(rails_env: Rails.env, build_environment: ENV.fetch("APP_BUILD_ENVIRONMENT", Rails.env))
    return unless rails_env.to_s == "development"
    return unless build_environment.to_s == "dev"

    seed_checklist(SPL_SHAKEDOWN_CHECKLIST)
  end

  private

  def seed_checklist(attributes)
    checklist = Checklist.find_or_initialize_by(title: attributes[:title])
    checklist.assign_attributes(
      notes: attributes[:notes],
      status: attributes[:status],
      start_at: attributes[:start_at]
    )
    checklist.save!

    attributes[:items].each do |item_attributes|
      checklist.checklist_items.find_or_initialize_by(item_text: item_attributes[:item_text]).tap do |item|
        item.assign_attributes(
          sort_order: item_attributes[:sort_order],
          desired_completion_offset_minutes: item_attributes[:desired_completion_offset_minutes]
        )
        item.save!
      end
    end
  end
end
