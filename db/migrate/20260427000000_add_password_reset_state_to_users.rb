class AddPasswordResetStateToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :password_reset_code_digest
      t.datetime :password_reset_code_sent_at
      t.integer :password_reset_attempts, default: 0, null: false
    end
  end
end
