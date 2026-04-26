class AddEmailVerificationToUsers < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :email_verified_at, :datetime
    add_column :users, :verification_code_digest, :string
    add_column :users, :verification_code_sent_at, :datetime
    add_column :users, :verification_attempts, :integer, null: false, default: 0

    execute <<~SQL
      UPDATE users
      SET email_verified_at = COALESCE(email_verified_at, created_at)
    SQL
  end

  def down
    remove_column :users, :verification_attempts
    remove_column :users, :verification_code_sent_at
    remove_column :users, :verification_code_digest
    remove_column :users, :email_verified_at
  end
end
