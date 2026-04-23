module ApplicationHelper
  def checklist_completion_for(checklist_item)
    @completion_lookup ||= current_user.checklist_item_completions.includes(:checklist_item).index_by(&:checklist_item_id)
    @completion_lookup[checklist_item.id]
  end

  def formatted_checklist_time(value)
    return "Not set" if value.blank?

    value.in_time_zone("UTC").strftime("%Y-%m-%d %H:%M UTC")
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
