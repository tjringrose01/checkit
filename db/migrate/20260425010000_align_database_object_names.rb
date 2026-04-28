class AlignDatabaseObjectNames < ActiveRecord::Migration[7.1]
  def change
    rename_index :users, "index_users_on_user_id", "users_user_id_key"
    rename_index :users, "index_users_on_email", "users_email_key"

    rename_index :checklists, "index_checklists_on_status", "idx_checklists_status"

    rename_index :checklist_items,
                 "index_checklist_items_on_checklist_id",
                 "idx_checklist_items_checklist_id"
    rename_index :checklist_items,
                 "index_checklist_items_on_checklist_id_and_sort_order",
                 "idx_checklist_items_checklist_id_sort_order"

    rename_index :checklist_item_completions,
                 "index_checklist_item_completions_on_checklist_item_id",
                 "idx_checklist_item_completions_checklist_item_id"
    rename_index :checklist_item_completions,
                 "index_checklist_item_completions_on_user_id",
                 "idx_checklist_item_completions_user_id"
    rename_index :checklist_item_completions,
                 "index_checklist_item_completions_uniqueness",
                 "checklist_item_completions_user_id_checklist_item_id_key"
  end
end
