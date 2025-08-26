class AddEnabledRemarketingToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :enabled_remarketing, :boolean, default: false
  end
end
