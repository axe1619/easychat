class AddMaxSessionsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :max_sessions, :integer, default: 1, null: false
  end
end
