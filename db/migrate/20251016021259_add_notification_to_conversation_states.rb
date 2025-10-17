class AddNotificationToConversationStates < ActiveRecord::Migration[7.0]
  def change
    add_column :conversation_states, :notification, :jsonb,  default: {}
  end
end
