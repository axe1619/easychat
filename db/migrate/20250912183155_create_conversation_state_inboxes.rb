class CreateConversationStateInboxes < ActiveRecord::Migration[7.0]
  def change
    create_table :conversation_state_inboxes do |t|
      t.bigint  :inbox_id, null: false
      t.bigint  :conversation_state_id, null: false
      t.timestamps
    end
    add_index :conversation_state_inboxes, [:inbox_id, :conversation_state_id], unique: true, name: 'index_conversation_state_inboxes'
  end
end
