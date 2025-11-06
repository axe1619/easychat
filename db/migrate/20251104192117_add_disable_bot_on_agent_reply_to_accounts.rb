class AddDisableBotOnAgentReplyToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :disable_bot_on_agent_reply, :boolean, null: false, default: false
  end
end
