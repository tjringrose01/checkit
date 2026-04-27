module ApplicationHelper
  CHECKLIST_ITEM_HTML_TAGS = %w[
    a
    b
    br
    code
    em
    i
    li
    ol
    p
    span
    strong
    u
    ul
  ].freeze
  CHECKLIST_ITEM_HTML_ATTRIBUTES = %w[href title target rel].freeze

  def checklist_completion_for(checklist_item)
    @completion_lookup ||= current_user.checklist_item_completions.includes(:checklist_item).index_by(&:checklist_item_id)
    @completion_lookup[checklist_item.id]
  end

  def render_checklist_item_content(checklist_item)
    sanitize(
      checklist_item.item_text,
      tags: CHECKLIST_ITEM_HTML_TAGS,
      attributes: CHECKLIST_ITEM_HTML_ATTRIBUTES
    )
  end

  def login_screen?
    controller_name == "sessions" && action_name == "new"
  end

  def menu_icon(name)
    icons = {
      menu: <<~SVG,
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M4 7H20" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/>
          <path d="M4 12H20" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/>
          <path d="M4 17H20" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/>
        </svg>
      SVG
      home: <<~SVG,
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M4 11.5L12 5L20 11.5V19C20 19.5523 19.5523 20 19 20H15V14H9V20H5C4.44772 20 4 19.5523 4 19V11.5Z" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>
        </svg>
      SVG
      admin: <<~SVG,
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M12 8.5A3.5 3.5 0 1 1 12 15.5A3.5 3.5 0 0 1 12 8.5Z" stroke="currentColor" stroke-width="1.8"/>
          <path d="M19 12L21 10.8L19.8 8.7L17.5 9L16.2 7L14 8L12 6.8L10 8L7.8 7L6.5 9L4.2 8.7L3 10.8L5 12L3 13.2L4.2 15.3L6.5 15L7.8 17L10 16L12 17.2L14 16L16.2 17L17.5 15L19.8 15.3L21 13.2L19 12Z" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>
        </svg>
      SVG
      checklist_management: <<~SVG,
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M12 8.5A3.5 3.5 0 1 1 12 15.5A3.5 3.5 0 0 1 12 8.5Z" stroke="currentColor" stroke-width="1.8"/>
          <path d="M19 12L21 10.8L19.8 8.7L17.5 9L16.2 7L14 8L12 6.8L10 8L7.8 7L6.5 9L4.2 8.7L3 10.8L5 12L3 13.2L4.2 15.3L6.5 15L7.8 17L10 16L12 17.2L14 16L16.2 17L17.5 15L19.8 15.3L21 13.2L19 12Z" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>
          <path d="M9 12.5L11 14.5L15.5 10" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      SVG
      signout: <<~SVG
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M14 7L19 12L14 17" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M19 12H9" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
          <path d="M11 5H6C5.44772 5 5 5.44772 5 6V18C5 18.5523 5.44772 19 6 19H11" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
        </svg>
      SVG
    }

    icons.fetch(name).html_safe
  end

  def browser_local_time(value)
    return "Not set" if value.blank?

    time_value =
      case value
      when String
        Time.zone.parse(value)
      else
        value.in_time_zone
      end

    return "Not set" if time_value.blank?

    iso_value = time_value.iso8601

    content_tag(
      :time,
      time_value.strftime("%Y-%m-%d %H:%M"),
      datetime: iso_value,
      data: { local_datetime: iso_value }
    )
  end

  def browser_local_clock_time(value)
    return "Not set" if value.blank?

    time_value =
      case value
      when String
        Time.zone.parse(value)
      else
        value.in_time_zone
      end

    return "Not set" if time_value.blank?

    iso_value = time_value.iso8601

    content_tag(
      :time,
      time_value.strftime("%I:%M %p"),
      datetime: iso_value,
      data: { local_datetime: iso_value, local_format: "time" }
    )
  end

  def formatted_wall_clock_time(value)
    return "Not set" if value.blank?

    time_value =
      case value
      when String
        Time.zone.parse(value)
      else
        value.in_time_zone("UTC")
      end

    return "Not set" if time_value.blank?

    time_value.strftime("%I:%M %p")
  end

  def formatted_checklist_offset(minutes)
    return "Not set" if minutes.blank? && minutes != 0

    "#{minutes} minute#{'s' unless minutes.to_i == 1} from start"
  end

  def checklist_completion_percentage(checklist)
    total_items = checklist.checklist_items.size
    return 0 if total_items.zero?

    max_target_offset = checklist.checklist_items.map { |item| item.desired_completion_offset_minutes.to_i }.max.to_i

    if max_target_offset.positive?
      completed_target_offset = checklist.checklist_items.filter_map do |item|
        item.desired_completion_offset_minutes.to_i if checklist_completion_for(item)&.completed?
      end.max.to_i

      return ((completed_target_offset.to_f / max_target_offset) * 100).round
    end

    completed_items = checklist.checklist_items.count { |item| checklist_completion_for(item)&.completed? }
    ((completed_items.to_f / total_items) * 100).round
  end

  def application_name
    ENV.fetch("APP_NAME", "Checkit")
  end

  def build_environment
    ENV.fetch("APP_BUILD_ENVIRONMENT", Rails.env)
  end

  def build_number
    ENV.fetch("APP_BUILD_NUMBER", "local")
  end

  def build_identifier
    "#{build_environment}-#{build_number}"
  end

  def build_timestamp
    ENV.fetch("APP_BUILD_TIMESTAMP", "unknown")
  end

  def application_version
    ENV["APP_VERSION"].presence
  end

  def git_sha
    ENV.fetch("APP_GIT_SHA", "unknown")
  end

  def version_or_revision_label
    if application_version.present?
      "Version #{application_version}"
    else
      "Commit #{git_sha.first(12)}"
    end
  end

  def footer_metadata
    [
      application_name,
      "Copyright #{Time.current.year}",
      "#{build_environment.to_s.capitalize} Environment",
      "Build #{build_identifier}"
    ]
  end

  def footer_build_timestamp
    safe_join(["Built ", browser_local_time(build_timestamp)])
  end

  def time_field_value(value)
    return if value.blank?

    value.in_time_zone("UTC").strftime("%I:%M %p")
  end

  def formatted_deviation(completion)
    return "Pending" unless completion&.completed?

    seconds = completion.completion_deviation_seconds.to_i
    return "On time" if seconds.zero?

    minutes = (seconds.abs / 60.0).round
    label = completion.deviation_status.tr("_", " ")
    "#{label.titleize} by #{minutes} minute#{'s' unless minutes == 1}"
  end
end
