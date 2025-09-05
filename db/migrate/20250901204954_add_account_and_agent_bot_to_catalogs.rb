class AddAccountAndAgentBotToCatalogs < ActiveRecord::Migration[7.0]
  def change
    add_reference :catalogs, :account,   null: false, foreign_key: true, index: true
    add_reference :catalogs, :agent_bot, null: false, foreign_key: true, index: true

    add_index :catalogs, [:account_id, :agent_bot_id]
  end
end
