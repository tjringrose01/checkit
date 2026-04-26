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
      version_or_revision_label,
      "Build #{build_identifier}",
      "Environment #{build_environment}",
      "Built #{build_timestamp}",
      "Copyright #{Time.current.year}"
    ]
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
