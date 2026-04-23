# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_04_23_012400) do
  create_table "checklist_item_completions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "checklist_item_id", null: false
    t.boolean "completed", default: false, null: false
    t.datetime "actual_completed_at"
    t.integer "completion_deviation_seconds"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checklist_item_id"], name: "index_checklist_item_completions_on_checklist_item_id"
    t.index ["user_id", "checklist_item_id"], name: "index_checklist_item_completions_uniqueness", unique: true
    t.index ["user_id"], name: "index_checklist_item_completions_on_user_id"
  end

  create_table "checklist_items", force: :cascade do |t|
    t.integer "checklist_id", null: false
    t.text "item_text", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "desired_completion_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checklist_id", "sort_order"], name: "index_checklist_items_on_checklist_id_and_sort_order"
    t.index ["checklist_id"], name: "index_checklist_items_on_checklist_id"
  end

  create_table "checklists", force: :cascade do |t|
    t.string "title", null: false
    t.text "notes"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_checklists_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "user_id", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "user", null: false
    t.integer "failed_login_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.datetime "last_login_at"
    t.boolean "must_change_password", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "enabled", default: true, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["user_id"], name: "index_users_on_user_id", unique: true
  end

  add_foreign_key "checklist_item_completions", "checklist_items"
  add_foreign_key "checklist_item_completions", "users"
  add_foreign_key "checklist_items", "checklists"
end
