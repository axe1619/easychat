class AddExpiresAtToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :expires_at, :datetime
  end
end
