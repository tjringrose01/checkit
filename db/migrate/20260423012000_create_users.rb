class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :user_id, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "user"
      t.integer :failed_login_attempts, null: false, default: 0
      t.datetime :locked_at
      t.datetime :last_login_at
      t.boolean :must_change_password, null: false, default: false

      t.timestamps
    end

    add_index :users, :user_id, unique: true
    add_index :users, :email, unique: true
  end
end
