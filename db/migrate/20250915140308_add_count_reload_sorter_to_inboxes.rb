class AddCountReloadSorterToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :count_reload_conversation_state, :integer
  end
end 