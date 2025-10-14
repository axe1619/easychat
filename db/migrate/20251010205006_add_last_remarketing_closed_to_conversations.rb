class AddLastRemarketingClosedToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :last_remarketing_closed, :datetime
  end
end
