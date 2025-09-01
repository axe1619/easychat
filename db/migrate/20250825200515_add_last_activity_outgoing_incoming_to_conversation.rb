class AddLastActivityOutgoingIncomingToConversation < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :last_activity_outgoing_at, :datetime
    add_column :conversations, :last_activity_incoming_at, :datetime
  end
end
