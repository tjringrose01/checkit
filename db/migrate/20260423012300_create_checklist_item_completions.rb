class CreateChecklistItemCompletions < ActiveRecord::Migration[7.1]
  def change
    create_table :checklist_item_completions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :checklist_item, null: false, foreign_key: true
      t.boolean :completed, null: false, default: false
      t.datetime :actual_completed_at
      t.integer :completion_deviation_seconds

      t.timestamps
    end

    add_index :checklist_item_completions,
              [ :user_id, :checklist_item_id ],
              unique: true,
              name: "index_checklist_item_completions_uniqueness"
  end
end
