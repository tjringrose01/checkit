class AddEnabledToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :enabled, :boolean, null: false, default: true
  end
end
