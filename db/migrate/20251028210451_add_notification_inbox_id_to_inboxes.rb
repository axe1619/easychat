class AddNotificationInboxIdToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :notification_inbox_id, :integer
  end
end
