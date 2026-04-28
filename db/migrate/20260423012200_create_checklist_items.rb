class CreateChecklistItems < ActiveRecord::Migration[7.1]
  def change
    create_table :checklist_items do |t|
      t.references :checklist, null: false, foreign_key: true
      t.text :item_text, null: false
      t.integer :sort_order, null: false, default: 0
      t.datetime :desired_completion_at

      t.timestamps
    end

    add_index :checklist_items, [ :checklist_id, :sort_order ]
  end
end
