class AddEnabledRemarketingToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :enabled_remarketing, :boolean, null: false, default: false
  end
end
