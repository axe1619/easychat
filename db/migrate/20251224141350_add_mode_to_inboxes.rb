class AddModeToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :mode, :string, default: "active", null: false
  end
end
