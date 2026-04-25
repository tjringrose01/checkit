require "csv"

class ChecklistItemCsvImport
  REQUIRED_HEADERS = %w[item_text sort_order desired_completion_at].freeze
  OPTIONAL_HEADERS = %w[checklist_item_id].freeze

  attr_reader :errors

  def initialize(checklist:, file:)
    @checklist = checklist
    @file = file
    @errors = []
  end

  def call
    return error!("CSV file is required.") unless file.respond_to?(:read)

    parsed_rows = parse_rows
    return false if errors.any?

    ChecklistItem.transaction do
      parsed_rows.each_with_index do |row, index|
        save_row!(row, index + 2)
      end
    end

    errors.empty?
  rescue ActiveRecord::RecordInvalid => error
    false
  end

  private

  attr_reader :checklist, :file

  def parse_rows
    csv = CSV.parse(file.read, headers: true)
    headers = csv.headers.compact
    missing_headers = REQUIRED_HEADERS - headers
    return error!("CSV is missing required headers: #{missing_headers.join(', ')}") if missing_headers.any?

    csv
  rescue CSV::MalformedCSVError => error
    error!("CSV is malformed: #{error.message}")
  end

  def save_row!(row, line_number)
    checklist_item = find_or_build_item(row)
    checklist_item.assign_attributes(
      item_text: row.fetch("item_text"),
      sort_order: row.fetch("sort_order"),
      desired_completion_at: parsed_time(row["desired_completion_at"], line_number)
    )

    raise ActiveRecord::RecordInvalid, checklist_item if errors.any?

    return if checklist_item.save

    error!("Row #{line_number}: #{checklist_item.errors.full_messages.to_sentence}")
    raise ActiveRecord::RecordInvalid, checklist_item
  end

  def find_or_build_item(row)
    if row["checklist_item_id"].present?
      return checklist.checklist_items.find_or_initialize_by(id: row["checklist_item_id"])
    end

    checklist.checklist_items.new
  end

  def parsed_time(value, line_number)
    return nil if value.blank?

    Time.zone.parse(value)
  rescue ArgumentError, TypeError
    error!("Row #{line_number}: desired_completion_at is invalid")
    nil
  end

  def error!(message)
    errors << message
    false
  end
end
