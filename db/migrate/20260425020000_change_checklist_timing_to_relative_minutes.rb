class ChangeChecklistTimingToRelativeMinutes < ActiveRecord::Migration[7.1]
  class MigrationChecklist < ApplicationRecord
    self.table_name = "checklists"

    has_many :checklist_items,
             class_name: "ChangeChecklistTimingToRelativeMinutes::MigrationChecklistItem",
             foreign_key: :checklist_id
  end

  class MigrationChecklistItem < ApplicationRecord
    self.table_name = "checklist_items"

    belongs_to :checklist,
               class_name: "ChangeChecklistTimingToRelativeMinutes::MigrationChecklist",
               foreign_key: :checklist_id
  end

  def up
    add_column :checklists, :start_at, :datetime
    add_column :checklist_items, :desired_completion_offset_minutes, :integer

    MigrationChecklist.reset_column_information
    MigrationChecklistItem.reset_column_information

    MigrationChecklist.find_each do |checklist|
      desired_times = checklist.checklist_items.where.not(desired_completion_at: nil).order(:desired_completion_at)
      start_at = desired_times.pick(:desired_completion_at) || checklist.created_at || Time.current
      checklist.update_columns(start_at:)

      checklist.checklist_items.find_each do |item|
        next if item.desired_completion_at.blank? || start_at.blank?

        offset_minutes = ((item.desired_completion_at.to_i - start_at.to_i) / 60.0).round
        item.update_columns(desired_completion_offset_minutes: offset_minutes)
      end
    end

    change_column_null :checklists, :start_at, false
    change_column_default :checklist_items, :desired_completion_offset_minutes, 0
    ChecklistItemWhereDesiredCompletionOffsetNull.new.execute
    change_column_null :checklist_items, :desired_completion_offset_minutes, false

    remove_column :checklist_items, :desired_completion_at, :datetime
  end

  def down
    add_column :checklist_items, :desired_completion_at, :datetime

    MigrationChecklist.reset_column_information
    MigrationChecklistItem.reset_column_information

    MigrationChecklist.includes(:checklist_items).find_each do |checklist|
      checklist.checklist_items.find_each do |item|
        desired_completion_at =
          if checklist.start_at.present?
            checklist.start_at + item.desired_completion_offset_minutes.to_i.minutes
          end

        item.update_columns(desired_completion_at:)
      end
    end

    remove_column :checklist_items, :desired_completion_offset_minutes, :integer
    remove_column :checklists, :start_at, :datetime
  end

  class ChecklistItemWhereDesiredCompletionOffsetNull
    def execute
      MigrationChecklistItem.where(desired_completion_offset_minutes: nil).update_all(desired_completion_offset_minutes: 0)
    end
  end
end
