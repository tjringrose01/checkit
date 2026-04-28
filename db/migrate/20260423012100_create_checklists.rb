class CreateChecklists < ActiveRecord::Migration[7.1]
  def change
    create_table :checklists do |t|
      t.string :title, null: false
      t.text :notes
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :checklists, :status
  end
end
